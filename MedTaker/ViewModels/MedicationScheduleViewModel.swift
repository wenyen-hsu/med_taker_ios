import Foundation
import SwiftUI

/// 藥物排程管理的 ViewModel
@MainActor
class MedicationScheduleViewModel: ObservableObject {
    @Published var schedules: [MedicationSchedule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let persistence = DataPersistenceService.shared
    private let api = SupabaseService.shared
    private let notificationService = NotificationService.shared

    init() {
        loadSchedules()
    }

    /// 載入所有排程
    func loadSchedules() {
        isLoading = true
        errorMessage = nil

        // 首先從本地載入
        schedules = persistence.fetchSchedules()

        // 然後嘗試從 API 同步
        Task {
            do {
                let apiSchedules = try await api.fetchSchedules()
                schedules = apiSchedules
                persistence.saveAllSchedules(apiSchedules)
                isLoading = false
            } catch {
                // 如果 API 失敗，繼續使用本地資料
                errorMessage = "無法同步資料：\(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    /// 新增排程
    func addSchedule(_ schedule: MedicationSchedule) {
        // 立即更新本地
        schedules.append(schedule)
        schedules.sort { $0.scheduledTime < $1.scheduledTime }
        persistence.addSchedule(schedule)

        // 創建通知
        notificationService.scheduleNotification(for: schedule)

        // 同步到 API
        Task {
            do {
                try await api.addSchedule(schedule)
            } catch {
                errorMessage = "新增排程失敗：\(error.localizedDescription)"
                showError = true
            }
        }
    }

    /// 更新排程
    func updateSchedule(_ schedule: MedicationSchedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
            schedules.sort { $0.scheduledTime < $1.scheduledTime }
            persistence.updateSchedule(schedule)

            // 更新通知
            if schedule.isActive {
                notificationService.scheduleNotification(for: schedule)
            } else {
                notificationService.cancelNotification(id: schedule.id)
            }

            Task {
                do {
                    try await api.updateSchedule(schedule)
                } catch {
                    errorMessage = "更新排程失敗：\(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    /// 刪除排程
    func deleteSchedule(_ schedule: MedicationSchedule) {
        schedules.removeAll { $0.id == schedule.id }
        persistence.deleteSchedule(id: schedule.id)

        // 取消通知
        notificationService.cancelNotification(id: schedule.id)

        Task {
            do {
                try await api.deleteSchedule(id: schedule.id)
            } catch {
                errorMessage = "刪除排程失敗：\(error.localizedDescription)"
                showError = true
            }
        }
    }

    /// 切換排程活動狀態
    func toggleScheduleActive(_ schedule: MedicationSchedule) {
        var updated = schedule
        updated.isActive.toggle()
        updateSchedule(updated)
    }

    /// 獲取活動的排程
    var activeSchedules: [MedicationSchedule] {
        schedules.filter { $0.isActive }
    }
}
