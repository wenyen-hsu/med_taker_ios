import Foundation

/// 藥物排程模型
struct MedicationSchedule: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var dosage: String
    var scheduledTime: Date
    var frequency: Frequency
    var activeDays: [Int]? // 0-6 表示星期日到星期六
    var startDate: Date
    var endDate: Date?
    var isActive: Bool

    enum Frequency: String, Codable, CaseIterable {
        case daily = "每日"
        case weekly = "每週"
        case custom = "自訂"

        var identifier: String {
            switch self {
            case .daily: return "daily"
            case .weekly: return "weekly"
            case .custom: return "custom"
            }
        }

        init(from identifier: String) {
            switch identifier {
            case "daily": self = .daily
            case "weekly": self = .weekly
            case "custom": self = .custom
            default: self = .daily
            }
        }
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        dosage: String,
        scheduledTime: Date,
        frequency: Frequency,
        activeDays: [Int]? = nil,
        startDate: Date,
        endDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.scheduledTime = scheduledTime
        self.frequency = frequency
        self.activeDays = activeDays
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
    }
}
