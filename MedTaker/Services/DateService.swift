import Foundation

/// 日期和時間相關的業務邏輯服務
class DateService {
    static let shared = DateService()

    private init() {}

    /// 判斷實際服藥時間是否準時（容差 ±15 分鐘）
    /// - Parameters:
    ///   - scheduled: 預定時間
    ///   - actual: 實際時間
    /// - Returns: 是否準時
    func isOnTime(scheduled: Date, actual: Date) -> Bool {
        let diffMinutes = Calendar.current.dateComponents([.minute], from: scheduled, to: actual).minute ?? 0
        return abs(diffMinutes) <= 15
    }

    /// 計算狀態基於預定和實際時間
    /// - Parameters:
    ///   - scheduled: 預定時間
    ///   - actual: 實際時間
    /// - Returns: 用藥狀態
    func calculateStatus(scheduled: Date, actual: Date) -> MedicationStatus {
        return isOnTime(scheduled: scheduled, actual: actual) ? .onTime : .late
    }

    /// 判斷某個排程在特定日期是否應該生成用藥記錄
    /// - Parameters:
    ///   - schedule: 藥物排程
    ///   - date: 目標日期
    /// - Returns: 是否應該生成記錄
    func shouldGenerateMedication(schedule: MedicationSchedule, for date: Date) -> Bool {
        // 檢查排程是否活動
        guard schedule.isActive else { return false }

        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let startDate = calendar.startOfDay(for: schedule.startDate)

        // 檢查是否在日期範圍內
        if targetDate < startDate {
            return false
        }

        if let endDate = schedule.endDate {
            let end = calendar.startOfDay(for: endDate)
            if targetDate > end {
                return false
            }
        }

        // 根據頻率判斷
        switch schedule.frequency {
        case .daily:
            return true

        case .weekly:
            guard let activeDays = schedule.activeDays else { return false }
            let weekday = date.weekday
            return activeDays.contains(weekday)

        case .custom:
            // 自訂邏輯可以在這裡擴展
            return false
        }
    }

    /// 為指定日期生成每日用藥記錄
    /// - Parameters:
    ///   - date: 目標日期
    ///   - schedules: 所有藥物排程
    /// - Returns: 該日應有的用藥記錄列表
    func generateDailyRecords(for date: Date, schedules: [MedicationSchedule]) -> [DailyMedicationRecord] {
        var records: [DailyMedicationRecord] = []

        for schedule in schedules {
            if shouldGenerateMedication(schedule: schedule, for: date) {
                let record = DailyMedicationRecord.from(schedule: schedule, date: date)
                records.append(record)
            }
        }

        // 按預定時間排序
        return records.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    /// 更新過期的「待服用」記錄為「錯過」
    /// - Parameter records: 記錄列表
    /// - Returns: 更新後的記錄列表
    func updateExpiredRecords(_ records: [DailyMedicationRecord]) -> [DailyMedicationRecord] {
        let now = Date()

        return records.map { record in
            var updated = record

            // 如果是過去的日期且狀態仍是「待服用」，改為「錯過」
            if record.status == .upcoming && record.scheduledTime < now {
                let calendar = Calendar.current
                let recordDate = calendar.startOfDay(for: record.date)
                let today = calendar.startOfDay(for: now)

                if recordDate < today {
                    updated.status = .missed
                }
            }

            return updated
        }
    }

    /// 獲取月份的統計資料
    /// - Parameters:
    ///   - records: 該月的所有記錄
    /// - Returns: 月份統計
    func calculateMonthStatistics(from records: [DailyMedicationRecord]) -> MonthStatistics {
        var monthStats = MonthStatistics()

        // 按日期分組
        let calendar = Calendar.current
        let groupedByDate = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.date)
        }

        // 計算每日統計
        for (date, dailyRecords) in groupedByDate {
            let stats = DailyStatistics.from(records: dailyRecords)
            monthStats.dateRecords[date] = stats
        }

        return monthStats
    }

    /// 格式化時間差（用於顯示遲到/早到的時間）
    /// - Parameters:
    ///   - scheduled: 預定時間
    ///   - actual: 實際時間
    /// - Returns: 格式化的時間差字串
    func formatTimeDifference(scheduled: Date, actual: Date) -> String {
        let diffMinutes = Calendar.current.dateComponents([.minute], from: scheduled, to: actual).minute ?? 0

        if diffMinutes == 0 {
            return "準時"
        } else if diffMinutes > 0 {
            return "遲到 \(diffMinutes) 分鐘"
        } else {
            return "提前 \(abs(diffMinutes)) 分鐘"
        }
    }
}
