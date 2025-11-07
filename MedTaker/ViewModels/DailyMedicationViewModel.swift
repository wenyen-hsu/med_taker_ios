import Foundation
import SwiftUI

/// 每日藥物追蹤的 ViewModel
@MainActor
class DailyMedicationViewModel: ObservableObject {
    @Published var medications: [DailyMedicationRecord] = []
    @Published var statistics = DailyStatistics.empty
    @Published var selectedDate: Date
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let persistence = DataPersistenceService.shared
    private let api = SupabaseService.shared
    private let dateService = DateService.shared

    init(date: Date = Date()) {
        self.selectedDate = date
        loadMedications()
    }

    /// 載入指定日期的藥物記錄
    func loadMedications() {
        isLoading = true

        // 先從本地載入
        var localRecords = persistence.fetchRecords(for: selectedDate)

        // 如果本地沒有記錄，生成預設記錄
        if localRecords.isEmpty {
            let schedules = DataPersistenceService.shared.fetchSchedules()
            localRecords = dateService.generateDailyRecords(for: selectedDate, schedules: schedules)

            // 儲存生成的記錄
            for record in localRecords {
                persistence.addRecord(record)
            }
        }

        // 更新過期記錄的狀態
        localRecords = dateService.updateExpiredRecords(localRecords)

        medications = localRecords.sorted { $0.scheduledTime < $1.scheduledTime }
        statistics = DailyStatistics.from(records: medications)

        // 從 API 同步
        Task {
            do {
                let apiRecords = try await api.fetchDailyRecords(for: selectedDate)

                if !apiRecords.isEmpty {
                    let updatedRecords = dateService.updateExpiredRecords(apiRecords)
                    medications = updatedRecords.sorted { $0.scheduledTime < $1.scheduledTime }
                    statistics = DailyStatistics.from(records: medications)

                    // 更新本地
                    for record in apiRecords {
                        persistence.updateRecord(record)
                    }
                }

                isLoading = false
            } catch {
                errorMessage = "同步失敗：\(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    /// 記錄服藥
    func logIntake(id: String, actualTime: Date, notes: String?) {
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }

        var record = medications[index]
        record.actualTime = actualTime
        record.notes = notes
        record.status = dateService.calculateStatus(scheduled: record.scheduledTime, actual: actualTime)

        medications[index] = record
        statistics = DailyStatistics.from(records: medications)

        persistence.updateRecord(record)

        Task {
            do {
                try await api.updateRecord(record)
            } catch {
                errorMessage = "記錄失敗：\(error.localizedDescription)"
                showError = true
            }
        }
    }

    /// 標記為跳過
    func markAsSkipped(id: String) {
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }

        var record = medications[index]
        record.status = .skipped

        medications[index] = record
        statistics = DailyStatistics.from(records: medications)

        persistence.updateRecord(record)

        Task {
            do {
                try await api.updateRecord(record)
            } catch {
                errorMessage = "標記失敗：\(error.localizedDescription)"
                showError = true
            }
        }
    }

    /// 取消記錄（恢復為待服用）
    func cancelRecord(id: String) {
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }

        var record = medications[index]
        record.status = .upcoming
        record.actualTime = nil
        record.notes = nil

        medications[index] = record
        statistics = DailyStatistics.from(records: medications)

        persistence.updateRecord(record)

        Task {
            do {
                try await api.updateRecord(record)
            } catch {
                errorMessage = "取消失敗：\(error.localizedDescription)"
                showError = true
            }
        }
    }

    /// 更改日期
    func changeDate(_ newDate: Date) {
        selectedDate = newDate
        loadMedications()
    }

    /// 前一天
    func previousDay() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            changeDate(newDate)
        }
    }

    /// 後一天
    func nextDay() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
            changeDate(newDate)
        }
    }

    /// 回到今天
    func goToToday() {
        changeDate(Date())
    }

    /// 日期標題
    var dateTitle: String {
        selectedDate.displayString
    }

    /// 是否為今天
    var isToday: Bool {
        selectedDate.isToday
    }
}
