import Foundation

/// 每日用藥記錄模型
struct DailyMedicationRecord: Identifiable, Codable, Equatable {
    let id: String
    let scheduleId: String
    var medicationName: String
    var dosage: String
    var scheduledTime: Date
    var date: Date
    var status: MedicationStatus
    var actualTime: Date?
    var notes: String?

    init(
        id: String = UUID().uuidString,
        scheduleId: String,
        medicationName: String,
        dosage: String,
        scheduledTime: Date,
        date: Date,
        status: MedicationStatus = .upcoming,
        actualTime: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.scheduleId = scheduleId
        self.medicationName = medicationName
        self.dosage = dosage
        self.scheduledTime = scheduledTime
        self.date = date
        self.status = status
        self.actualTime = actualTime
        self.notes = notes
    }

    /// 從排程創建每日記錄
    static func from(schedule: MedicationSchedule, date: Date) -> DailyMedicationRecord {
        let scheduledTime = Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: schedule.scheduledTime),
            minute: Calendar.current.component(.minute, from: schedule.scheduledTime),
            second: 0,
            of: date
        ) ?? date

        return DailyMedicationRecord(
            scheduleId: schedule.id,
            medicationName: schedule.name,
            dosage: schedule.dosage,
            scheduledTime: scheduledTime,
            date: date,
            status: .upcoming
        )
    }

    /// 轉換為 API 請求格式
    func toAPIFormat() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "scheduleId": scheduleId,
            "medicationName": medicationName,
            "dosage": dosage,
            "scheduledTime": scheduledTime.timeString(),
            "date": date.dateString(),
            "status": status.rawValue
        ]

        if let actualTime = actualTime {
            dict["actualTime"] = actualTime.timeString()
        }

        if let notes = notes {
            dict["notes"] = notes
        }

        return dict
    }

    /// 從 API 響應創建實例
    static func fromAPIResponse(_ data: [String: Any]) -> DailyMedicationRecord? {
        guard
            let id = data["id"] as? String,
            let scheduleId = data["scheduleId"] as? String,
            let medicationName = data["medicationName"] as? String,
            let dosage = data["dosage"] as? String,
            let scheduledTimeStr = data["scheduledTime"] as? String,
            let dateStr = data["date"] as? String,
            let statusStr = data["status"] as? String
        else {
            return nil
        }

        let scheduledTime = Date.fromTimeString(scheduledTimeStr) ?? Date()
        let date = Date.fromDateString(dateStr) ?? Date()
        let status = MedicationStatus(rawValue: statusStr) ?? .upcoming

        let actualTime: Date? = {
            if let actualTimeStr = data["actualTime"] as? String {
                return Date.fromTimeString(actualTimeStr)
            }
            return nil
        }()

        let notes = data["notes"] as? String

        return DailyMedicationRecord(
            id: id,
            scheduleId: scheduleId,
            medicationName: medicationName,
            dosage: dosage,
            scheduledTime: scheduledTime,
            date: date,
            status: status,
            actualTime: actualTime,
            notes: notes
        )
    }
}
