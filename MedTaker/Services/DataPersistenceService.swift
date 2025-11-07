import Foundation

/// 本地資料持久化服務（使用 UserDefaults 進行簡單存儲）
/// 注意：實際生產環境建議使用 Core Data 或 SwiftData
class DataPersistenceService {
    static let shared = DataPersistenceService()

    private let schedulesKey = "medication_schedules"
    private let recordsKey = "medication_records"

    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - 排程 CRUD

    /// 儲存所有排程
    private func saveSchedules(_ schedules: [MedicationSchedule]) {
        if let encoded = try? encoder.encode(schedules) {
            userDefaults.set(encoded, forKey: schedulesKey)
        }
    }

    /// 獲取所有排程
    func fetchSchedules() -> [MedicationSchedule] {
        guard let data = userDefaults.data(forKey: schedulesKey),
              let schedules = try? decoder.decode([MedicationSchedule].self, from: data) else {
            return []
        }
        return schedules
    }

    /// 新增排程
    func addSchedule(_ schedule: MedicationSchedule) {
        var schedules = fetchSchedules()
        schedules.append(schedule)
        saveSchedules(schedules)
    }

    /// 更新排程
    func updateSchedule(_ schedule: MedicationSchedule) {
        var schedules = fetchSchedules()
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
            saveSchedules(schedules)
        }
    }

    /// 刪除排程
    func deleteSchedule(id: String) {
        var schedules = fetchSchedules()
        schedules.removeAll { $0.id == id }
        saveSchedules(schedules)
    }

    /// 批量儲存排程（用於同步）
    func saveAllSchedules(_ schedules: [MedicationSchedule]) {
        saveSchedules(schedules)
    }

    // MARK: - 記錄 CRUD

    /// 儲存所有記錄
    private func saveRecords(_ records: [DailyMedicationRecord]) {
        if let encoded = try? encoder.encode(records) {
            userDefaults.set(encoded, forKey: recordsKey)
        }
    }

    /// 獲取所有記錄
    func fetchAllRecords() -> [DailyMedicationRecord] {
        guard let data = userDefaults.data(forKey: recordsKey),
              let records = try? decoder.decode([DailyMedicationRecord].self, from: data) else {
            return []
        }
        return records
    }

    /// 獲取指定日期的記錄
    func fetchRecords(for date: Date) -> [DailyMedicationRecord] {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        return fetchAllRecords().filter { record in
            let recordDate = calendar.startOfDay(for: record.date)
            return recordDate == targetDate
        }
    }

    /// 獲取日期範圍內的記錄
    func fetchRecords(from startDate: Date, to endDate: Date) -> [DailyMedicationRecord] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        return fetchAllRecords().filter { record in
            let recordDate = calendar.startOfDay(for: record.date)
            return recordDate >= start && recordDate <= end
        }
    }

    /// 新增記錄
    func addRecord(_ record: DailyMedicationRecord) {
        var records = fetchAllRecords()
        records.append(record)
        saveRecords(records)
    }

    /// 更新記錄
    func updateRecord(_ record: DailyMedicationRecord) {
        var records = fetchAllRecords()
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            saveRecords(records)
        }
    }

    /// 刪除記錄
    func deleteRecord(id: String) {
        var records = fetchAllRecords()
        records.removeAll { $0.id == id }
        saveRecords(records)
    }

    /// 刪除所有記錄
    func deleteAllRecords() -> Int {
        let count = fetchAllRecords().count
        userDefaults.removeObject(forKey: recordsKey)
        return count
    }

    /// 批量儲存記錄（用於同步）
    func saveAllRecords(_ records: [DailyMedicationRecord]) {
        saveRecords(records)
    }

    // MARK: - 查詢輔助方法

    /// 檢查某個排程在某日是否已有記錄
    func hasRecord(scheduleId: String, date: Date) -> Bool {
        let records = fetchRecords(for: date)
        return records.contains { $0.scheduleId == scheduleId }
    }

    /// 獲取某個排程的所有記錄
    func fetchRecords(for scheduleId: String) -> [DailyMedicationRecord] {
        return fetchAllRecords().filter { $0.scheduleId == scheduleId }
    }

    /// 清除所有資料（用於測試或重置）
    func clearAllData() {
        userDefaults.removeObject(forKey: schedulesKey)
        userDefaults.removeObject(forKey: recordsKey)
    }
}
