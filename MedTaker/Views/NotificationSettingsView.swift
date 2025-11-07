import SwiftUI

/// 通知設定視圖
struct NotificationSettingsView: View {
    @ObservedObject var notificationService = NotificationService.shared
    @State private var showPermissionSheet = false

    var body: some View {
        Form {
            // 通知狀態
            Section {
                statusRow
            } header: {
                Text("通知狀態")
            }

            // 通知設定
            if notificationService.authorizationStatus == .authorized {
                Section {
                    Toggle("開啟服藥提醒", isOn: $notificationService.isNotificationEnabled)
                        .onChange(of: notificationService.isNotificationEnabled) { _, newValue in
                            if newValue {
                                notificationService.rescheduleAllNotifications()
                            } else {
                                // 取消所有通知
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }

                    if notificationService.isNotificationEnabled {
                        Picker("提前提醒時間", selection: $notificationService.reminderMinutesBefore) {
                            Text("5 分鐘").tag(5)
                            Text("10 分鐘").tag(10)
                            Text("15 分鐘").tag(15)
                            Text("30 分鐘").tag(30)
                        }
                        .onChange(of: notificationService.reminderMinutesBefore) { _, _ in
                            // 重新排程所有通知
                            notificationService.rescheduleAllNotifications()
                        }
                    }
                } header: {
                    Text("提醒設定")
                } footer: {
                    Text("系統會在預定服藥時間前提醒您")
                }

                // 測試通知
                Section {
                    Button("發送測試通知") {
                        notificationService.scheduleTestNotification()
                    }
                } header: {
                    Text("測試")
                } footer: {
                    Text("測試通知將在 5 秒後顯示")
                }

                // 通知統計
                Section {
                    NotificationStatsView()
                } header: {
                    Text("通知統計")
                }
            }
        }
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPermissionSheet) {
            NotificationPermissionView()
        }
    }

    // MARK: - 狀態行

    @ViewBuilder
    private var statusRow: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.headline)

                Text(statusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if notificationService.authorizationStatus == .denied {
                Button("開啟") {
                    notificationService.openSettings()
                }
                .font(.subheadline)
            } else if notificationService.authorizationStatus == .notDetermined {
                Button("授權") {
                    showPermissionSheet = true
                }
                .font(.subheadline)
            }
        }
    }

    private var statusIcon: String {
        switch notificationService.authorizationStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        case .provisional:
            return "bell.badge.fill"
        case .ephemeral:
            return "clock.badge.fill"
        @unknown default:
            return "bell.fill"
        }
    }

    private var statusColor: Color {
        switch notificationService.authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        default:
            return .gray
        }
    }

    private var statusText: String {
        switch notificationService.authorizationStatus {
        case .authorized:
            return "已授權"
        case .denied:
            return "已拒絕"
        case .notDetermined:
            return "尚未決定"
        case .provisional:
            return "臨時授權"
        case .ephemeral:
            return "短期授權"
        @unknown default:
            return "未知狀態"
        }
    }

    private var statusDescription: String {
        switch notificationService.authorizationStatus {
        case .authorized:
            return "您將收到服藥提醒通知"
        case .denied:
            return "請到設定中開啟通知權限"
        case .notDetermined:
            return "點擊「授權」開啟通知"
        default:
            return ""
        }
    }
}

/// 通知統計視圖
struct NotificationStatsView: View {
    @State private var pendingCount = 0

    var body: some View {
        HStack {
            Text("待發送通知")
                .foregroundColor(.secondary)

            Spacer()

            Text("\(pendingCount)")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .task {
            await loadStats()
        }
    }

    private func loadStats() async {
        pendingCount = await NotificationService.shared.getPendingNotificationCount()
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
    }
}
