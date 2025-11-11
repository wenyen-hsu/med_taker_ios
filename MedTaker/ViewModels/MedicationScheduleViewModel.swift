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

        isLoading = false
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

        // 在背景執行緒生成記錄，避免阻塞 UI
        Task.detached(priority: .userInitiated) {
            await self.generateRecordsForSchedule(schedule)
        }
    }

    /// 為新排程生成每日記錄（在背景執行緒）
    private func generateRecordsForSchedule(_ schedule: MedicationSchedule) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateService = DateService.shared

        // 獲取所有現有記錄（一次性讀取）
        var allRecords = persistence.fetchAllRecords()

        // 生成未來 60 天的新記錄
        var newRecords: [DailyMedicationRecord] = []

        for dayOffset in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            // 檢查該排程在該日期是否應該生成記錄
            if dateService.shouldGenerateMedication(schedule: schedule, for: date) {
                // 檢查是否已存在該排程在該日期的記錄
                let alreadyExists = allRecords.contains {
                    $0.scheduleId == schedule.id &&
                    calendar.isDate($0.date, inSameDayAs: date)
                }

                if !alreadyExists {
                    let record = DailyMedicationRecord.from(schedule: schedule, date: date)
                    newRecords.append(record)
                }
            }
        }

        // 批次儲存所有新記錄（一次性寫入）
        if !newRecords.isEmpty {
            allRecords.append(contentsOf: newRecords)
            persistence.saveAllRecords(allRecords)
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
