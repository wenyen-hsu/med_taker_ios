import Foundation
import SwiftUI
import Combine

/// 日曆視圖的 ViewModel
@MainActor
class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var currentMonth = Date()
    @Published var monthStatistics = MonthStatistics()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let persistence = DataPersistenceService.shared
    private let dateService = DateService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadMonth(Date())

        NotificationCenter.default.publisher(for: .schedulesUpdated)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.loadMonth(self.currentMonth)
            }
            .store(in: &cancellables)
    }

    /// 載入指定月份的統計資料
    func loadMonth(_ date: Date) {
        isLoading = true
        currentMonth = date

        let startOfMonth = date.startOfMonth()
        let endOfMonth = date.endOfMonth()

        // 獲取所有排程並清除已刪除排程的殘留記錄
        let schedules = persistence.fetchSchedules()
        let validIds = Set(schedules.map { $0.id })
        persistence.deleteRecordsNotIn(scheduleIds: validIds)

        // 為月份中的每一天生成記錄（如果不存在）
        generateMonthRecords(from: startOfMonth, to: endOfMonth, schedules: schedules)

        // 從本地載入所有記錄
        var localRecords = persistence.fetchRecords(from: startOfMonth, to: endOfMonth)
        localRecords = localRecords.filter { validIds.contains($0.scheduleId) }

        // 更新過期記錄的狀態
        localRecords = dateService.updateExpiredRecords(localRecords)

        // 計算統計
        monthStatistics = dateService.calculateMonthStatistics(from: localRecords)

        isLoading = false
    }

    /// 為月份中的每一天生成記錄（如果不存在）
    private func generateMonthRecords(from startDate: Date, to endDate: Date, schedules: [MedicationSchedule]) {
        let calendar = Calendar.current
        var currentDate = startDate

        while currentDate <= endDate {
            var records = persistence.fetchRecords(for: currentDate)

            for schedule in schedules {
                guard dateService.shouldGenerateMedication(schedule: schedule, for: currentDate) else {
                    continue
                }

                let hasRecord = records.contains { $0.scheduleId == schedule.id }
                if !hasRecord {
                    let record = DailyMedicationRecord.from(schedule: schedule, date: currentDate)
                    records.append(record)
                    persistence.addRecord(record)
                }
            }

            // 移到下一天
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
    }

    /// 選擇日期
    func selectDate(_ date: Date) {
        selectedDate = date

        // 如果選擇的日期在不同月份，重新載入
        let calendar = Calendar.current
        if !calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
            loadMonth(date)
        }
    }

    /// 移動到上個月
    func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            loadMonth(newMonth)
        }
    }

    /// 移動到下個月
    func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            loadMonth(newMonth)
        }
    }

    /// 回到今天
    func goToToday() {
        let today = Date()
        selectedDate = today
        loadMonth(today)
    }

    /// 獲取某日的顏色指示
    func colorForDate(_ date: Date) -> Color? {
        return monthStatistics.dayColor(for: date)
    }

    /// 獲取某日的統計
    func statisticsForDate(_ date: Date) -> DailyStatistics? {
        return monthStatistics.statistics(for: date)
    }

    /// 月份標題
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: currentMonth)
    }
}
