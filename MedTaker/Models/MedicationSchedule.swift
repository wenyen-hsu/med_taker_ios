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

    /// 轉換為 API 請求格式
    func toAPIFormat() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "dosage": dosage,
            "scheduledTime": scheduledTime.timeString(),
            "frequency": frequency.identifier,
            "startDate": startDate.dateString(),
            "isActive": isActive
        ]

        if let activeDays = activeDays {
            dict["activeDays"] = activeDays
        }

        if let endDate = endDate {
            dict["endDate"] = endDate.dateString()
        }

        return dict
    }

    /// 從 API 響應創建實例
    static func fromAPIResponse(_ data: [String: Any]) -> MedicationSchedule? {
        guard
            let id = data["id"] as? String,
            let name = data["name"] as? String,
            let dosage = data["dosage"] as? String,
            let scheduledTimeStr = data["scheduledTime"] as? String,
            let frequencyStr = data["frequency"] as? String,
            let startDateStr = data["startDate"] as? String,
            let isActive = data["isActive"] as? Bool
        else {
            return nil
        }

        let scheduledTime = Date.fromTimeString(scheduledTimeStr) ?? Date()
        let frequency = Frequency(from: frequencyStr)
        let startDate = Date.fromDateString(startDateStr) ?? Date()
        let activeDays = data["activeDays"] as? [Int]
        let endDate: Date? = {
            if let endDateStr = data["endDate"] as? String {
                return Date.fromDateString(endDateStr)
            }
            return nil
        }()

        return MedicationSchedule(
            id: id,
            name: name,
            dosage: dosage,
            scheduledTime: scheduledTime,
            frequency: frequency,
            activeDays: activeDays,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive
        )
    }
}
