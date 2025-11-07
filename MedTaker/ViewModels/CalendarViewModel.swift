import Foundation
import SwiftUI

/// 日曆視圖的 ViewModel
@MainActor
class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var currentMonth = Date()
    @Published var monthStatistics = MonthStatistics()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let persistence = DataPersistenceService.shared
    private let api = SupabaseService.shared
    private let dateService = DateService.shared

    init() {
        loadMonth(Date())
    }

    /// 載入指定月份的統計資料
    func loadMonth(_ date: Date) {
        isLoading = true
        currentMonth = date

        let startOfMonth = date.startOfMonth()
        let endOfMonth = date.endOfMonth()

        // 先從本地載入
        let localRecords = persistence.fetchRecords(from: startOfMonth, to: endOfMonth)
        monthStatistics = dateService.calculateMonthStatistics(from: localRecords)

        // 從 API 同步
        Task {
            do {
                let apiRecords = try await api.fetchRecordsRange(from: startOfMonth, to: endOfMonth)
                monthStatistics = dateService.calculateMonthStatistics(from: apiRecords)

                // 更新本地資料
                persistence.saveAllRecords(apiRecords)

                isLoading = false
            } catch {
                errorMessage = "載入月份資料失敗：\(error.localizedDescription)"
                isLoading = false
            }
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
