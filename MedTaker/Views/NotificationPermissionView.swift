import SwiftUI

/// 通知權限請求引導視圖
struct NotificationPermissionView: View {
    @ObservedObject var notificationService = NotificationService.shared
    @Environment(\.dismiss) var dismiss
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // 圖示
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding()

            // 標題
            Text("開啟服藥提醒")
                .font(.title.bold())

            // 說明文字
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "clock.fill",
                    title: "準時提醒",
                    description: "在服藥時間前提醒您，不會錯過"
                )

                FeatureRow(
                    icon: "checkmark.circle.fill",
                    title: "快速記錄",
                    description: "直接從通知記錄服藥，方便快捷"
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "提升依從性",
                    description: "定時提醒幫助您養成規律服藥習慣"
                )
            }
            .padding(.horizontal)

            Spacer()

            // 按鈕
            VStack(spacing: 12) {
                Button(action: {
                    requestPermission()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "bell.fill")
                            Text("開啟通知")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isRequesting)

                Button("稍後設定") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .padding()
    }

    private func requestPermission() {
        isRequesting = true

        Task {
            let granted = await notificationService.requestAuthorization()

            await MainActor.run {
                isRequesting = false

                if granted {
                    // 權限獲得，排程所有通知
                    notificationService.rescheduleAllNotifications()
                    dismiss()
                } else {
                    // 權限被拒，顯示提示
                    // 可以顯示 Alert 引導用戶到設定
                }
            }
        }
    }
}

/// 功能說明行
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NotificationPermissionView()
}
