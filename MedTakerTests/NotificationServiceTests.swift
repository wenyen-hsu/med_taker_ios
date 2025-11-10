import XCTest
@testable import MedTaker

/// NotificationService 的單元測試
final class NotificationServiceTests: XCTestCase {
    var notificationService: NotificationService!

    override func setUp() {
        super.setUp()
        notificationService = NotificationService.shared
    }

    override func tearDown() {
        // 清除所有測試通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        super.tearDown()
    }

    // MARK: - 通知排程測試

    func testScheduleNotification_Daily() async {
        // 創建每日排程
        let schedule = MedicationSchedule(
            name: "測試藥物",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date(),
            isActive: true
        )

        // 排程通知
        notificationService.scheduleNotification(for: schedule)

        // 等待一下讓通知排程完成
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒

        // 驗證通知已創建
        let count = await notificationService.getPendingNotificationCount()
        XCTAssertGreaterThan(count, 0, "應該有至少一個待發送的通知")
    }

    func testScheduleNotification_Weekly() async {
        // 創建每週排程（週一、三、五）
        let schedule = MedicationSchedule(
            name: "週測試藥物",
            dosage: "20mg",
            scheduledTime: Date(),
            frequency: .weekly,
            activeDays: [1, 3, 5], // 週一、三、五
            startDate: Date(),
            isActive: true
        )

        notificationService.scheduleNotification(for: schedule)

        try? await Task.sleep(nanoseconds: 100_000_000)

        let count = await notificationService.getPendingNotificationCount()
        XCTAssertGreaterThanOrEqual(count, 3, "每週排程應該有 3 個通知（週一、三、五）")
    }

    func testCancelNotification() async {
        let schedule = MedicationSchedule(
            id: "test-schedule-123",
            name: "測試藥物",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date(),
            isActive: true
        )

        // 排程通知
        notificationService.scheduleNotification(for: schedule)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // 取消通知
        notificationService.cancelNotification(id: schedule.id)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // 驗證通知已取消
        let requests = await notificationService.getPendingNotifications()
        let hasScheduleNotification = requests.contains { $0.identifier == schedule.id }
        XCTAssertFalse(hasScheduleNotification, "通知應該已被取消")
    }

    func testUpdateNotifications() async {
        let schedules = [
            MedicationSchedule(
                id: "schedule-1",
                name: "藥物 1",
                dosage: "10mg",
                scheduledTime: Date(),
                frequency: .daily,
                startDate: Date(),
                isActive: true
            ),
            MedicationSchedule(
                id: "schedule-2",
                name: "藥物 2",
                dosage: "20mg",
                scheduledTime: Date(),
                frequency: .daily,
                startDate: Date(),
                isActive: false // 未啟用
            )
        ]

        notificationService.updateNotifications(for: schedules)
        try? await Task.sleep(nanoseconds: 200_000_000)

        let count = await notificationService.getPendingNotificationCount()
        // 只有活動的排程會創建通知
        XCTAssertGreaterThan(count, 0, "應該至少有一個通知（活動排程）")
    }

    func testNotificationContent() async {
        let schedule = MedicationSchedule(
            id: "content-test",
            name: "測試內容藥物",
            dosage: "30mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date(),
            isActive: true
        )

        notificationService.scheduleNotification(for: schedule)
        try? await Task.sleep(nanoseconds: 100_000_000)

        let requests = await notificationService.getPendingNotifications()
        guard let request = requests.first(where: { $0.identifier == schedule.id }) else {
            XCTFail("找不到通知")
            return
        }

        let content = request.content
        XCTAssertEqual(content.title, "服藥提醒")
        XCTAssertTrue(content.body.contains(schedule.name))
        XCTAssertTrue(content.body.contains(schedule.dosage))
        XCTAssertEqual(content.categoryIdentifier, "MEDICATION_REMINDER")
    }

    func testSnoozeNotification() async {
        let scheduleId = "snooze-test"

        notificationService.snoozeNotification(scheduleId: scheduleId)
        try? await Task.sleep(nanoseconds: 100_000_000)

        let requests = await notificationService.getPendingNotifications()
        let hasSnoozeNotification = requests.contains { $0.identifier.contains("snooze") }
        XCTAssertTrue(hasSnoozeNotification, "應該有稍後提醒通知")
    }

    // MARK: - 通知設定測試

    func testReminderMinutesBeforeSetting() {
        let originalValue = notificationService.reminderMinutesBefore

        // 測試更改設定
        notificationService.reminderMinutesBefore = 10
        XCTAssertEqual(notificationService.reminderMinutesBefore, 10)

        notificationService.reminderMinutesBefore = 15
        XCTAssertEqual(notificationService.reminderMinutesBefore, 15)

        // 恢復原值
        notificationService.reminderMinutesBefore = originalValue
    }

    func testNotificationEnabledSetting() {
        let originalValue = notificationService.isNotificationEnabled

        notificationService.isNotificationEnabled = false
        XCTAssertFalse(notificationService.isNotificationEnabled)

        notificationService.isNotificationEnabled = true
        XCTAssertTrue(notificationService.isNotificationEnabled)

        // 恢復原值
        notificationService.isNotificationEnabled = originalValue
    }

    // MARK: - 整合測試

    func testCompleteNotificationFlow() async {
        // 1. 創建排程
        let schedule = MedicationSchedule(
            id: "flow-test",
            name: "完整流程測試",
            dosage: "40mg",
            scheduledTime: Date(),
            frequency: .daily,
            startDate: Date(),
            isActive: true
        )

        // 2. 排程通知
        notificationService.scheduleNotification(for: schedule)
        try? await Task.sleep(nanoseconds: 100_000_000)

        let initialCount = await notificationService.getPendingNotificationCount()
        XCTAssertGreaterThan(initialCount, 0)

        // 3. 取消通知
        notificationService.cancelNotification(id: schedule.id)
        try? await Task.sleep(nanoseconds: 100_000_000)

        let finalCount = await notificationService.getPendingNotificationCount()
        XCTAssertLessThan(finalCount, initialCount)
    }
}
