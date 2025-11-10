import Foundation
import SwiftUI
import Combine

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
        notifySchedulesChanged()

        // 創建通知
        notificationService.scheduleNotification(for: schedule)

        // 為該排程生成未來的每日記錄（從今天開始的 60 天）
        generateRecordsForSchedule(schedule)

        // 同步到 API（靜默失敗，因為本地已保存）
        Task {
            do {
                try await api.addSchedule(schedule)
            } catch {
                // 僅記錄錯誤，不顯示給用戶，因為本地已成功保存
                print("⚠️ API 同步失敗（排程已保存到本地）：\(error.localizedDescription)")
                // 可選：顯示較溫和的提示
                // errorMessage = "排程已保存，但雲端同步失敗"
                // showError = true
            }
        }
    }

    /// 為新排程生成每日記錄
    private func generateRecordsForSchedule(_ schedule: MedicationSchedule) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateService = DateService.shared

        // 生成未來 60 天的記錄
        for dayOffset in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            // 檢查該排程在該日期是否應該生成記錄
            if dateService.shouldGenerateMedication(schedule: schedule, for: date) {
                // 檢查是否已存在該排程在該日期的記錄
                let existingRecords = persistence.fetchRecords(for: date)
                let alreadyExists = existingRecords.contains { $0.scheduleId == schedule.id }

                if !alreadyExists {
                    let record = DailyMedicationRecord.from(schedule: schedule, date: date)
                    persistence.addRecord(record)
                }
            }
        }
    }

    /// 更新排程
    func updateSchedule(_ schedule: MedicationSchedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
            schedules.sort { $0.scheduledTime < $1.scheduledTime }
            persistence.updateSchedule(schedule)
            notifySchedulesChanged()

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
                    // 僅記錄錯誤，不顯示給用戶，因為本地已成功保存
                    print("⚠️ API 同步失敗（排程已更新到本地）：\(error.localizedDescription)")
                }
            }
        }
    }

    /// 刪除排程
    func deleteSchedule(_ schedule: MedicationSchedule) {
        schedules.removeAll { $0.id == schedule.id }
        persistence.deleteSchedule(id: schedule.id)

        // 刪除該排程的所有每日記錄
        let deletedCount = persistence.deleteRecords(for: schedule.id)
        print("✓ 刪除排程 '\(schedule.name)' 及其 \(deletedCount) 條記錄")
        notifySchedulesChanged()

        // 取消通知
        notificationService.cancelNotification(id: schedule.id)

        Task {
            do {
                try await api.deleteSchedule(id: schedule.id)
            } catch {
                // 僅記錄錯誤，不顯示給用戶，因為本地已成功刪除
                print("⚠️ API 同步失敗（排程已從本地刪除）：\(error.localizedDescription)")
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

    private func notifySchedulesChanged() {
        NotificationCenter.default.post(name: .schedulesUpdated, object: nil)
    }
}

extension Notification.Name {
    static let schedulesUpdated = Notification.Name("schedulesUpdated")
}
