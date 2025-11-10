import XCTest
@testable import MedTaker

/// DateService 的單元測試
final class DateServiceTests: XCTestCase {
    var dateService: DateService!

    override func setUp() {
        super.setUp()
        dateService = DateService.shared
    }

    // MARK: - isOnTime 測試

    func testIsOnTime_WithinTolerance_ReturnsTrue() {
        let scheduled = Date()
        let actual = scheduled.addingTimeInterval(10 * 60) // +10 分鐘

        XCTAssertTrue(dateService.isOnTime(scheduled: scheduled, actual: actual))
    }

    func testIsOnTime_ExactlyOnTime_ReturnsTrue() {
        let scheduled = Date()
        let actual = scheduled

        XCTAssertTrue(dateService.isOnTime(scheduled: scheduled, actual: actual))
    }

    func testIsOnTime_Within15MinutesEarly_ReturnsTrue() {
        let scheduled = Date()
        let actual = scheduled.addingTimeInterval(-15 * 60) // -15 分鐘

        XCTAssertTrue(dateService.isOnTime(scheduled: scheduled, actual: actual))
    }

    func testIsOnTime_OutsideTolerance_ReturnsFalse() {
        let scheduled = Date()
        let actual = scheduled.addingTimeInterval(20 * 60) // +20 分鐘

        XCTAssertFalse(dateService.isOnTime(scheduled: scheduled, actual: actual))
    }

    func testIsOnTime_VeryLate_ReturnsFalse() {
        let scheduled = Date()
        let actual = scheduled.addingTimeInterval(60 * 60) // +1 小時

        XCTAssertFalse(dateService.isOnTime(scheduled: scheduled, actual: actual))
    }

    // MARK: - calculateStatus 測試

    func testCalculateStatus_OnTime_ReturnsOnTime() {
        let scheduled = Date()
        let actual = scheduled.addingTimeInterval(5 * 60)

        let status = dateService.calculateStatus(scheduled: scheduled, actual: actual)

        XCTAssertEqual(status, .onTime)
    }

    func testCalculateStatus_Late_ReturnsLate() {
        let scheduled = Date()
        let actual = scheduled.addingTimeInterval(30 * 60)

        let status = dateService.calculateStatus(scheduled: scheduled, actual: actual)

        XCTAssertEqual(status, .late)
    }

    // MARK: - shouldGenerateMedication 測試

    func testShouldGenerateMedication_DailySchedule_ReturnsTrue() {
        let schedule = MedicationSchedule(
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date().addingTimeInterval(-86400), // 昨天開始
            isActive: true
        )

        let result = dateService.shouldGenerateMedication(schedule: schedule, for: Date())

        XCTAssertTrue(result)
    }

    func testShouldGenerateMedication_InactiveSchedule_ReturnsFalse() {
        let schedule = MedicationSchedule(
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date(),
            isActive: false
        )

        let result = dateService.shouldGenerateMedication(schedule: schedule, for: Date())

        XCTAssertFalse(result)
    }

    func testShouldGenerateMedication_BeforeStartDate_ReturnsFalse() {
        let tomorrow = Date().addingTimeInterval(86400)

        let schedule = MedicationSchedule(
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: tomorrow,
            isActive: true
        )

        let result = dateService.shouldGenerateMedication(schedule: schedule, for: Date())

        XCTAssertFalse(result)
    }

    func testShouldGenerateMedication_AfterEndDate_ReturnsFalse() {
        let yesterday = Date().addingTimeInterval(-86400)

        let schedule = MedicationSchedule(
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date().addingTimeInterval(-86400 * 7), // 一週前
            endDate: yesterday,
            isActive: true
        )

        let result = dateService.shouldGenerateMedication(schedule: schedule, for: Date())

        XCTAssertFalse(result)
    }

    func testShouldGenerateMedication_WeeklySchedule_OnActiveDay_ReturnsTrue() {
        let today = Date()
        let weekday = today.weekday

        let schedule = MedicationSchedule(
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .weekly,
            activeDays: [weekday],
            startDate: Date().addingTimeInterval(-86400),
            isActive: true
        )

        let result = dateService.shouldGenerateMedication(schedule: schedule, for: today)

        XCTAssertTrue(result)
    }

    func testShouldGenerateMedication_WeeklySchedule_OnInactiveDay_ReturnsFalse() {
        let today = Date()
        let weekday = today.weekday
        let differentDay = (weekday + 1) % 7

        let schedule = MedicationSchedule(
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .weekly,
            activeDays: [differentDay],
            startDate: Date().addingTimeInterval(-86400),
            isActive: true
        )

        let result = dateService.shouldGenerateMedication(schedule: schedule, for: today)

        XCTAssertFalse(result)
    }

    // MARK: - generateDailyRecords 測試

    func testGenerateDailyRecords_WithMultipleSchedules_ReturnsCorrectCount() {
        let schedules = [
            MedicationSchedule(
                name: "Med 1",
                dosage: "10mg",
                scheduledTime: Date(),
                frequency: .daily,
                startDate: Date(),
                isActive: true
            ),
            MedicationSchedule(
                name: "Med 2",
                dosage: "20mg",
                scheduledTime: Date(),
                frequency: .daily,
                startDate: Date(),
                isActive: true
            )
        ]

        let records = dateService.generateDailyRecords(for: Date(), schedules: schedules)

        XCTAssertEqual(records.count, 2)
    }

    func testGenerateDailyRecords_SortedByTime() {
        let calendar = Calendar.current
        let time1 = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        let time2 = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!

        let schedules = [
            MedicationSchedule(
                name: "Med 2",
                dosage: "20mg",
                scheduledTime: time2,
                frequency: .daily,
                startDate: Date(),
                isActive: true
            ),
            MedicationSchedule(
                name: "Med 1",
                dosage: "10mg",
                scheduledTime: time1,
                frequency: .daily,
                startDate: Date(),
                isActive: true
            )
        ]

        let records = dateService.generateDailyRecords(for: Date(), schedules: schedules)

        XCTAssertEqual(records.first?.medicationName, "Med 1")
        XCTAssertEqual(records.last?.medicationName, "Med 2")
    }

    // MARK: - updateExpiredRecords 測試

    func testUpdateExpiredRecords_PastDateUpcoming_ChangesToMissed() {
        let yesterday = Date().addingTimeInterval(-86400)

        var record = DailyMedicationRecord(
            scheduleId: "1",
            medicationName: "Test",
            dosage: "10mg",
            scheduledTime: yesterday,
            date: yesterday,
            status: .upcoming
        )

        let updated = dateService.updateExpiredRecords([record])

        XCTAssertEqual(updated.first?.status, .missed)
    }

    func testUpdateExpiredRecords_FutureDateUpcoming_RemainsUpcoming() {
        let tomorrow = Date().addingTimeInterval(86400)

        var record = DailyMedicationRecord(
            scheduleId: "1",
            medicationName: "Test",
            dosage: "10mg",
            scheduledTime: tomorrow,
            date: tomorrow,
            status: .upcoming
        )

        let updated = dateService.updateExpiredRecords([record])

        XCTAssertEqual(updated.first?.status, .upcoming)
    }
}
