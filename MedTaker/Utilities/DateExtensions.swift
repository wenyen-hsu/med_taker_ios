import Foundation

extension Date {
    /// 格式化為 YYYY-MM-DD 字串
    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }

    /// 格式化為 HH:mm 字串
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }

    /// 格式化為完整時間字串 (YYYY-MM-DD HH:mm)
    func fullTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }

    /// 從 YYYY-MM-DD 字串解析日期
    static func fromDateString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: string)
    }

    /// 從 HH:mm 字串解析時間（使用今天的日期）
    static func fromTimeString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        if let time = formatter.date(from: string) {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                minute: timeComponents.minute ?? 0,
                                second: 0,
                                of: Date())
        }
        return nil
    }

    /// 從完整時間字串解析 (YYYY-MM-DD HH:mm)
    static func fromFullTimeString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: string)
    }

    /// 獲取月份的第一天
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// 獲取月份的最後一天
    func endOfMonth() -> Date {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth()) else {
            return self
        }
        return calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? self
    }

    /// 檢查是否為今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 檢查是否為過去
    var isPast: Bool {
        self < Date()
    }

    /// 檢查是否為未來
    var isFuture: Bool {
        self > Date()
    }

    /// 獲取星期幾 (0 = 星期日, 6 = 星期六)
    var weekday: Int {
        Calendar.current.component(.weekday, from: self) - 1
    }

    /// 星期幾的名稱
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    /// 短星期名稱
    var shortWeekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    /// 格式化顯示（例如：12月25日 星期一）
    var displayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: self)
    }
}

extension Calendar {
    /// 生成日期範圍（包含起始和結束日期）
    func dateRange(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startOfDay(for: startDate)
        let end = startOfDay(for: endDate)

        while currentDate <= end {
            dates.append(currentDate)
            guard let nextDate = date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates
    }

    /// 獲取月份中的所有日期
    func datesInMonth(for date: Date) -> [Date] {
        let startOfMonth = date.startOfMonth()
        let endOfMonth = date.endOfMonth()
        return dateRange(from: startOfMonth, to: endOfMonth)
    }
}
