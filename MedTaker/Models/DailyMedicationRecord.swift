import Foundation

/// 每日用藥記錄模型
struct DailyMedicationRecord: Identifiable, Codable, Equatable, Hashable {
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
}
