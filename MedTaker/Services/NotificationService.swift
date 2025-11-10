import UserNotifications
import Foundation
import Combine
import UIKit

/// 本地推送通知服務
@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var hasRequestedPermission = false

    private let center = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    private let hasRequestedKey = "has_requested_notification_permission"

    // 通知設定
    @Published var reminderMinutesBefore: Int = 5 // 提前幾分鐘提醒
    @Published var isNotificationEnabled: Bool = true

    // 通知 Category 和 Action 識別符
    private let medicationReminderCategory = "MEDICATION_REMINDER"
    private let takeActionIdentifier = "TAKE_ACTION"
    private let snoozeActionIdentifier = "SNOOZE_ACTION"
    private let skipActionIdentifier = "SKIP_ACTION"

    override init() {
        super.init()
        center.delegate = self
        hasRequestedPermission = userDefaults.bool(forKey: hasRequestedKey)
        setupNotificationCategories()
        checkAuthorizationStatus()
    }

    // MARK: - 權限管理

    /// 檢查當前授權狀態
    func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    /// 請求通知權限
    /// - Returns: 是否獲得授權
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            await MainActor.run {
                hasRequestedPermission = true
                userDefaults.set(true, forKey: hasRequestedKey)
            }

            checkAuthorizationStatus()
            return granted
        } catch {
            print("通知權限請求失敗：\(error)")
            return false
        }
    }

    /// 開啟系統設定頁面
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - 通知 Category 設定

    /// 設定通知類別和操作
    private func setupNotificationCategories() {
        // 「已服用」操作（前景，需要開啟應用）
        let takeAction = UNNotificationAction(
            identifier: takeActionIdentifier,
            title: "已服用",
            options: [.foreground]
        )

        // 「稍後提醒」操作（背景）
        let snoozeAction = UNNotificationAction(
            identifier: snoozeActionIdentifier,
            title: "稍後提醒（15分鐘）",
            options: []
        )

        // 「跳過」操作（背景）
        let skipAction = UNNotificationAction(
            identifier: skipActionIdentifier,
            title: "跳過",
            options: [.destructive]
        )

        // 創建類別
        let category = UNNotificationCategory(
            identifier: medicationReminderCategory,
            actions: [takeAction, snoozeAction, skipAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        center.setNotificationCategories([category])
    }

    // MARK: - 通知排程

    /// 為藥物排程創建通知
    /// - Parameter schedule: 藥物排程
    func scheduleNotification(for schedule: MedicationSchedule) {
        guard isNotificationEnabled && authorizationStatus == .authorized else {
            return
        }

        // 取消舊的通知
        cancelNotification(id: schedule.id)

        let content = UNMutableNotificationContent()
        content.title = "服藥提醒"
        content.body = "\(schedule.name) - \(schedule.dosage)"
        content.sound = .default
        content.categoryIdentifier = medicationReminderCategory

        // 附加資料
        content.userInfo = [
            "scheduleId": schedule.id,
            "medicationName": schedule.name,
            "dosage": schedule.dosage
        ]

        // 根據頻率創建觸發器
        switch schedule.frequency {
        case .daily:
            scheduleDailyNotification(schedule: schedule, content: content)

        case .weekly:
            scheduleWeeklyNotification(schedule: schedule, content: content)

        case .custom:
            // 自訂頻率暫不支援
            break
        }
    }

    /// 排程每日重複通知
    private func scheduleDailyNotification(schedule: MedicationSchedule, content: UNMutableNotificationContent) {
        let calendar = Calendar.current

        // 計算提醒時間（提前幾分鐘）
        guard let reminderTime = calendar.date(
            byAdding: .minute,
            value: -reminderMinutesBefore,
            to: schedule.scheduledTime
        ) else {
            return
        }

        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: schedule.id,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("排程通知失敗：\(error)")
            } else {
                print("成功排程每日通知：\(schedule.name) at \(hour):\(minute)")
            }
        }
    }

    /// 排程每週重複通知
    private func scheduleWeeklyNotification(schedule: MedicationSchedule, content: UNMutableNotificationContent) {
        guard let activeDays = schedule.activeDays, !activeDays.isEmpty else {
            return
        }

        let calendar = Calendar.current

        // 計算提醒時間
        guard let reminderTime = calendar.date(
            byAdding: .minute,
            value: -reminderMinutesBefore,
            to: schedule.scheduledTime
        ) else {
            return
        }

        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)

        // 為每個活動日創建通知
        for dayIndex in activeDays {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = dayIndex + 1 // Calendar.weekday 從 1 開始（1 = 星期日）

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let requestId = "\(schedule.id)_day\(dayIndex)"
            let request = UNNotificationRequest(
                identifier: requestId,
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("排程週通知失敗：\(error)")
                } else {
                    print("成功排程週通知：\(schedule.name) on day \(dayIndex)")
                }
            }
        }
    }

    /// 取消通知
    /// - Parameter id: 排程 ID
    func cancelNotification(id: String) {
        // 取消所有相關的通知（包括每週的多個通知）
        var identifiers = [id]

        // 添加每週通知的所有變體
        for day in 0...6 {
            identifiers.append("\(id)_day\(day)")
        }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("取消通知：\(id)")
    }

    /// 更新所有排程的通知
    /// - Parameter schedules: 排程列表
    func updateNotifications(for schedules: [MedicationSchedule]) {
        // 取消所有現有通知
        center.removeAllPendingNotificationRequests()

        // 為活動的排程重新創建通知
        for schedule in schedules where schedule.isActive {
            scheduleNotification(for: schedule)
        }

        print("已更新 \(schedules.filter { $0.isActive }.count) 個通知")
    }

    /// 重新排程所有通知（例如：設定變更後）
    func rescheduleAllNotifications() {
        let schedules = DataPersistenceService.shared.fetchSchedules()
        updateNotifications(for: schedules)
    }

    /// 稍後提醒（延後 15 分鐘）
    /// - Parameter scheduleId: 排程 ID
    func snoozeNotification(scheduleId: String) {
        let content = UNMutableNotificationContent()
        content.title = "服藥提醒"
        content.body = "您稍早延後的服藥時間到了"
        content.sound = .default
        content.categoryIdentifier = medicationReminderCategory
        content.userInfo = ["scheduleId": scheduleId]

        // 15 分鐘後觸發
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(scheduleId)_snooze_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("稍後提醒設定失敗：\(error)")
            } else {
                print("已設定稍後提醒：15 分鐘後")
            }
        }
    }

    // MARK: - 測試用途

    /// 創建測試通知（5 秒後觸發）
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "測試通知"
        content.body = "這是一個測試通知"
        content.sound = .default
        content.categoryIdentifier = medicationReminderCategory

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(
            identifier: "test_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("測試通知失敗：\(error)")
            } else {
                print("測試通知將在 5 秒後觸發")
            }
        }
    }

    /// 取得待發送的通知列表（用於調試）
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }

    /// 取得通知數量
    func getPendingNotificationCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// 應用在前景時收到通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 即使應用在前景也顯示通知
        completionHandler([.banner, .sound, .badge])
    }

    /// 使用者點擊通知或通知操作
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let scheduleId = userInfo["scheduleId"] as? String else {
            completionHandler()
            return
        }

        Task { @MainActor in
            await handleNotificationAction(
                actionIdentifier: response.actionIdentifier,
                scheduleId: scheduleId
            )
            completionHandler()
        }
    }

    /// 處理通知操作
    private func handleNotificationAction(actionIdentifier: String, scheduleId: String) async {
        switch actionIdentifier {
        case takeActionIdentifier:
            // 「已服用」- 記錄服藥
            await handleTakeAction(scheduleId: scheduleId)

        case snoozeActionIdentifier:
            // 「稍後提醒」- 延後 15 分鐘
            snoozeNotification(scheduleId: scheduleId)

        case skipActionIdentifier:
            // 「跳過」- 標記為跳過
            await handleSkipAction(scheduleId: scheduleId)

        case UNNotificationDefaultActionIdentifier:
            // 點擊通知本身 - 開啟應用到每日視圖
            // TODO: 導航到對應的每日視圖
            break

        default:
            break
        }
    }

    /// 處理「已服用」操作
    private func handleTakeAction(scheduleId: String) async {
        // 找到對應的今日藥物記錄
        let today = Date()
        let records = DataPersistenceService.shared.fetchRecords(for: today)

        guard let record = records.first(where: { $0.scheduleId == scheduleId }) else {
            return
        }

        // 更新為已服用（以當前時間為實際時間）
        var updatedRecord = record
        updatedRecord.actualTime = Date()
        updatedRecord.status = DateService.shared.calculateStatus(
            scheduled: record.scheduledTime,
            actual: Date()
        )

        DataPersistenceService.shared.updateRecord(updatedRecord)

        // 同步到 API
        Task {
            try? await SupabaseService.shared.updateRecord(updatedRecord)
        }

        print("已記錄服藥：\(record.medicationName)")
    }

    /// 處理「跳過」操作
    private func handleSkipAction(scheduleId: String) async {
        let today = Date()
        let records = DataPersistenceService.shared.fetchRecords(for: today)

        guard let record = records.first(where: { $0.scheduleId == scheduleId }) else {
            return
        }

        var updatedRecord = record
        updatedRecord.status = .skipped

        DataPersistenceService.shared.updateRecord(updatedRecord)

        // 同步到 API
        Task {
            try? await SupabaseService.shared.updateRecord(updatedRecord)
        }

        print("已跳過：\(record.medicationName)")
    }
}
