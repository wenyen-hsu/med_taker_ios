import XCTest
import SwiftUI
@testable import MedTaker

/// MedicationStatus 和統計類型的測試
final class MedicationStatusTests: XCTestCase {

    // MARK: - MedicationStatus 測試

    func testMedicationStatus_DisplayNames() {
        XCTAssertEqual(MedicationStatus.upcoming.displayName, "待服用")
        XCTAssertEqual(MedicationStatus.onTime.displayName, "準時")
        XCTAssertEqual(MedicationStatus.late.displayName, "遲到")
        XCTAssertEqual(MedicationStatus.missed.displayName, "錯過")
        XCTAssertEqual(MedicationStatus.skipped.displayName, "跳過")
    }

    func testMedicationStatus_IsCompleted() {
        XCTAssertTrue(MedicationStatus.onTime.isCompleted)
        XCTAssertTrue(MedicationStatus.late.isCompleted)
        XCTAssertFalse(MedicationStatus.upcoming.isCompleted)
        XCTAssertFalse(MedicationStatus.missed.isCompleted)
        XCTAssertFalse(MedicationStatus.skipped.isCompleted)
    }

    // MARK: - DailyStatistics 測試

    func testDailyStatistics_Empty() {
        let stats = DailyStatistics.empty

        XCTAssertEqual(stats.total, 0)
        XCTAssertEqual(stats.completed, 0)
        XCTAssertEqual(stats.completionRate, 0)
    }

    func testDailyStatistics_FromRecords() {
        let records = [
            DailyMedicationRecord(
                scheduleId: "1",
                medicationName: "Med 1",
                dosage: "10mg",
                scheduledTime: Date(),
                date: Date(),
                status: .onTime
            ),
            DailyMedicationRecord(
                scheduleId: "2",
                medicationName: "Med 2",
                dosage: "20mg",
                scheduledTime: Date(),
                date: Date(),
                status: .late
            ),
            DailyMedicationRecord(
                scheduleId: "3",
                medicationName: "Med 3",
                dosage: "30mg",
                scheduledTime: Date(),
                date: Date(),
                status: .upcoming
            ),
            DailyMedicationRecord(
                scheduleId: "4",
                medicationName: "Med 4",
                dosage: "40mg",
                scheduledTime: Date(),
                date: Date(),
                status: .missed
            )
        ]

        let stats = DailyStatistics.from(records: records)

        XCTAssertEqual(stats.total, 4)
        XCTAssertEqual(stats.completed, 2)
        XCTAssertEqual(stats.onTime, 1)
        XCTAssertEqual(stats.late, 1)
        XCTAssertEqual(stats.upcoming, 1)
        XCTAssertEqual(stats.missed, 1)
        XCTAssertEqual(stats.completionRate, 50.0)
    }

    func testDailyStatistics_CompletionRate() {
        let records = [
            DailyMedicationRecord(
                scheduleId: "1",
                medicationName: "Med 1",
                dosage: "10mg",
                scheduledTime: Date(),
                date: Date(),
                status: .onTime
            ),
            DailyMedicationRecord(
                scheduleId: "2",
                medicationName: "Med 2",
                dosage: "20mg",
                scheduledTime: Date(),
                date: Date(),
                status: .onTime
            ),
            DailyMedicationRecord(
                scheduleId: "3",
                medicationName: "Med 3",
                dosage: "30mg",
                scheduledTime: Date(),
                date: Date(),
                status: .late
            ),
            DailyMedicationRecord(
                scheduleId: "4",
                medicationName: "Med 4",
                dosage: "40mg",
                scheduledTime: Date(),
                date: Date(),
                status: .upcoming
            )
        ]

        let stats = DailyStatistics.from(records: records)

        XCTAssertEqual(stats.completionRate, 75.0) // 3/4 = 75%
    }

    // MARK: - MonthStatistics 測試

    func testMonthStatistics_DayColor_AllOnTime() {
        var monthStats = MonthStatistics()
        let date = Date()

        var stats = DailyStatistics()
        stats.total = 3
        stats.onTime = 3
        stats.completed = 3

        monthStats.dateRecords[Calendar.current.startOfDay(for: date)] = stats

        let color = monthStats.dayColor(for: date)

        XCTAssertEqual(color, .green)
    }

    func testMonthStatistics_DayColor_AllCompletedWithLate() {
        var monthStats = MonthStatistics()
        let date = Date()

        var stats = DailyStatistics()
        stats.total = 3
        stats.onTime = 2
        stats.late = 1
        stats.completed = 3

        monthStats.dateRecords[Calendar.current.startOfDay(for: date)] = stats

        let color = monthStats.dayColor(for: date)

        XCTAssertEqual(color, .yellow)
    }

    func testMonthStatistics_DayColor_PartiallyCompleted() {
        var monthStats = MonthStatistics()
        let date = Date()

        var stats = DailyStatistics()
        stats.total = 3
        stats.onTime = 1
        stats.upcoming = 2
        stats.completed = 1

        monthStats.dateRecords[Calendar.current.startOfDay(for: date)] = stats

        let color = monthStats.dayColor(for: date)

        XCTAssertEqual(color, .orange)
    }

    func testMonthStatistics_DayColor_NoneCompleted() {
        var monthStats = MonthStatistics()
        let date = Date()

        var stats = DailyStatistics()
        stats.total = 3
        stats.missed = 3
        stats.completed = 0

        monthStats.dateRecords[Calendar.current.startOfDay(for: date)] = stats

        let color = monthStats.dayColor(for: date)

        XCTAssertEqual(color, .red)
    }

    func testMonthStatistics_DayColor_NoData() {
        let monthStats = MonthStatistics()
        let date = Date()

        let color = monthStats.dayColor(for: date)

        XCTAssertNil(color)
    }
}
