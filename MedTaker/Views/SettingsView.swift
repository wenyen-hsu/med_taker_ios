import SwiftUI

/// 設定視圖
struct SettingsView: View {
    @State private var showResetAlert = false
    @State private var showResetSuccess = false
    @State private var deletedCount = 0

    var body: some View {
        Form {
            // 關於
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("建置號碼")
                    Spacer()
                    Text("1")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("關於")
            }

            // 資料管理
            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("重置所有用藥記錄")
                    }
                }
            } header: {
                Text("資料管理")
            } footer: {
                Text("這將刪除所有用藥記錄，但保留藥物排程。此操作無法復原。")
            }

            // 說明
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(
                        icon: "calendar",
                        color: .blue,
                        title: "日曆視圖",
                        description: "查看每月服藥完成情況"
                    )

                    InfoRow(
                        icon: "pills.fill",
                        color: .purple,
                        title: "排程管理",
                        description: "新增和管理您的藥物排程"
                    )

                    InfoRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "記錄服藥",
                        description: "點擊「記錄服藥」按鈕記錄實際服用時間"
                    )

                    InfoRow(
                        icon: "clock",
                        color: .orange,
                        title: "準時提醒",
                        description: "系統會根據您的排程發送提醒通知"
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text("使用說明")
            }

            // 狀態說明
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    StatusRow(color: .green, text: "準時：在預定時間 ±15 分鐘內服用")
                    StatusRow(color: .yellow, text: "遲到：超過 15 分鐘後服用")
                    StatusRow(color: .orange, text: "跳過：主動標記為跳過")
                    StatusRow(color: .red, text: "錯過：過期未服用")
                }
                .padding(.vertical, 4)
            } header: {
                Text("狀態說明")
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.large)
        .alert("確認重置", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                resetAllRecords()
            }
        } message: {
            Text("確定要刪除所有用藥記錄嗎？此操作無法復原。")
        }
        .alert("重置完成", isPresented: $showResetSuccess) {
            Button("確定", role: .cancel) { }
        } message: {
            Text("已刪除 \(deletedCount) 筆記錄")
        }
    }

    private func resetAllRecords() {
        let persistence = DataPersistenceService.shared
        deletedCount = persistence.deleteAllRecords()
        showResetSuccess = true

        // 同步到 API
        Task {
            let api = SupabaseService.shared
            try? await api.resetAllRecords()
        }
    }
}

/// 資訊行
struct InfoRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// 狀態行
struct StatusRow: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
