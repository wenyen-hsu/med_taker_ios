import SwiftUI

/// 用藥狀態枚舉
enum MedicationStatus: String, Codable, CaseIterable {
    case upcoming = "upcoming"      // 待服用
    case onTime = "on-time"        // 準時服用
    case late = "late"             // 遲到服用
    case missed = "missed"         // 錯過
    case skipped = "skipped"       // 跳過

    /// 顯示名稱
    var displayName: String {
        switch self {
        case .upcoming: return "待服用"
        case .onTime: return "準時"
        case .late: return "遲到"
        case .missed: return "錯過"
        case .skipped: return "跳過"
        }
    }

    /// 狀態顏色
    var color: Color {
        switch self {
        case .upcoming: return .gray
        case .onTime: return .green
        case .late: return .yellow
        case .missed: return .red
        case .skipped: return .orange
        }
    }

    /// 圖標名稱
    var iconName: String {
        switch self {
        case .upcoming: return "clock"
        case .onTime: return "checkmark.circle.fill"
        case .late: return "exclamationmark.triangle.fill"
        case .missed: return "xmark.circle.fill"
        case .skipped: return "forward.fill"
        }
    }

    /// 是否已完成（已記錄）
    var isCompleted: Bool {
        switch self {
        case .onTime, .late: return true
        case .upcoming, .missed, .skipped: return false
        }
    }
}

/// 每日統計資料
struct DailyStatistics {
    var total: Int = 0
    var completed: Int = 0
    var onTime: Int = 0
    var late: Int = 0
    var missed: Int = 0
    var skipped: Int = 0
    var upcoming: Int = 0

    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }

    static var empty: DailyStatistics {
        return DailyStatistics()
    }

    /// 從記錄列表計算統計
    static func from(records: [DailyMedicationRecord]) -> DailyStatistics {
        var stats = DailyStatistics()
        stats.total = records.count

        for record in records {
            switch record.status {
            case .upcoming:
                stats.upcoming += 1
            case .onTime:
                stats.onTime += 1
                stats.completed += 1
            case .late:
                stats.late += 1
                stats.completed += 1
            case .missed:
                stats.missed += 1
            case .skipped:
                stats.skipped += 1
            }
        }

        return stats
    }
}

/// 月份統計資料（用於日曆視圖）
struct MonthStatistics {
    var dateRecords: [Date: DailyStatistics] = [:]

    /// 獲取某日的統計
    func statistics(for date: Date) -> DailyStatistics? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return dateRecords[normalizedDate]
    }

    /// 獲取某日的狀態顏色
    func dayColor(for date: Date) -> Color? {
        guard let stats = statistics(for: date) else { return nil }

        if stats.total == 0 {
            return nil
        }

        // 全部準時 - 綠色
        if stats.onTime == stats.total {
            return .green
        }

        // 全部完成但有遲到 - 黃色
        if stats.completed == stats.total && stats.late > 0 {
            return .yellow
        }

        // 部分完成 - 橙色
        if stats.completed > 0 && stats.completed < stats.total {
            return .orange
        }

        // 未完成 - 紅色
        if stats.completed == 0 && stats.total > 0 {
            return .red
        }

        return nil
    }
}
