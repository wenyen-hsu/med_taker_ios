import XCTest
@testable import MedTaker

/// DataPersistenceService 的單元測試
final class DataPersistenceServiceTests: XCTestCase {
    var service: DataPersistenceService!

    override func setUp() {
        super.setUp()
        service = DataPersistenceService.shared
        // 清除所有資料以確保測試獨立性
        service.clearAllData()
    }

    override func tearDown() {
        // 測試後清除資料
        service.clearAllData()
        super.tearDown()
    }

    // MARK: - 排程測試

    func testSaveAndFetchSchedule() {
        let schedule = MedicationSchedule(
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date(),
            isActive: true
        )

        service.addSchedule(schedule)
        let fetched = service.fetchSchedules()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Test Med")
        XCTAssertEqual(fetched.first?.dosage, "10mg")
    }

    func testUpdateSchedule() {
        var schedule = MedicationSchedule(
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date(),
            isActive: true
        )

        service.addSchedule(schedule)

        schedule.dosage = "20mg"
        service.updateSchedule(schedule)

        let fetched = service.fetchSchedules()

        XCTAssertEqual(fetched.first?.dosage, "20mg")
    }

    func testDeleteSchedule() {
        let schedule = MedicationSchedule(
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date(),
            isActive: true
        )

        service.addSchedule(schedule)
        XCTAssertEqual(service.fetchSchedules().count, 1)

        service.deleteSchedule(id: schedule.id)
        XCTAssertEqual(service.fetchSchedules().count, 0)
    }

    // MARK: - 記錄測試

    func testSaveAndFetchRecord() {
        let record = DailyMedicationRecord(
            scheduleId: "1",
            medicationName: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            date: Date()
        )

        service.addRecord(record)
        let fetched = service.fetchAllRecords()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.medicationName, "Test Med")
    }

    func testFetchRecordsForDate() {
        let today = Date()
        let yesterday = today.addingTimeInterval(-86400)

        let record1 = DailyMedicationRecord(
            scheduleId: "1",
            medicationName: "Med 1",
            dosage: "10mg",
            scheduledTime: today,
            date: today
        )

        let record2 = DailyMedicationRecord(
            scheduleId: "2",
            medicationName: "Med 2",
            dosage: "20mg",
            scheduledTime: yesterday,
            date: yesterday
        )

        service.addRecord(record1)
        service.addRecord(record2)

        let todayRecords = service.fetchRecords(for: today)

        XCTAssertEqual(todayRecords.count, 1)
        XCTAssertEqual(todayRecords.first?.medicationName, "Med 1")
    }

    func testFetchRecordsInRange() {
        let calendar = Calendar.current
        let today = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let record1 = DailyMedicationRecord(
            scheduleId: "1",
            medicationName: "Med 1",
            dosage: "10mg",
            scheduledTime: twoDaysAgo,
            date: twoDaysAgo
        )

        let record2 = DailyMedicationRecord(
            scheduleId: "2",
            medicationName: "Med 2",
            dosage: "20mg",
            scheduledTime: yesterday,
            date: yesterday
        )

        let record3 = DailyMedicationRecord(
            scheduleId: "3",
            medicationName: "Med 3",
            dosage: "30mg",
            scheduledTime: today,
            date: today
        )

        service.addRecord(record1)
        service.addRecord(record2)
        service.addRecord(record3)

        let rangeRecords = service.fetchRecords(from: yesterday, to: today)

        XCTAssertEqual(rangeRecords.count, 2)
    }

    func testUpdateRecord() {
        var record = DailyMedicationRecord(
            scheduleId: "1",
            medicationName: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            date: Date(),
            status: .upcoming
        )

        service.addRecord(record)

        record.status = .onTime
        record.actualTime = Date()
        service.updateRecord(record)

        let fetched = service.fetchAllRecords()

        XCTAssertEqual(fetched.first?.status, .onTime)
        XCTAssertNotNil(fetched.first?.actualTime)
    }

    func testDeleteRecord() {
        let record = DailyMedicationRecord(
            scheduleId: "1",
            medicationName: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            date: Date()
        )

        service.addRecord(record)
        XCTAssertEqual(service.fetchAllRecords().count, 1)

        service.deleteRecord(id: record.id)
        XCTAssertEqual(service.fetchAllRecords().count, 0)
    }

    func testDeleteAllRecords() {
        let record1 = DailyMedicationRecord(
            scheduleId: "1",
            medicationName: "Med 1",
            dosage: "10mg",
            scheduledTime: Date(),
            date: Date()
        )

        let record2 = DailyMedicationRecord(
            scheduleId: "2",
            medicationName: "Med 2",
            dosage: "20mg",
            scheduledTime: Date(),
            date: Date()
        )

        service.addRecord(record1)
        service.addRecord(record2)

        let deletedCount = service.deleteAllRecords()

        XCTAssertEqual(deletedCount, 2)
        XCTAssertEqual(service.fetchAllRecords().count, 0)
    }

    func testHasRecord() {
        let schedule = MedicationSchedule(
            id: "schedule-1",
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date(),
            isActive: true
        )

        let record = DailyMedicationRecord(
            scheduleId: schedule.id,
            medicationName: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            date: Date()
        )

        XCTAssertFalse(service.hasRecord(scheduleId: schedule.id, date: Date()))

        service.addRecord(record)

        XCTAssertTrue(service.hasRecord(scheduleId: schedule.id, date: Date()))
    }
}
