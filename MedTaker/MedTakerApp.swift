import SwiftUI

/// MedTaker iOS 應用程式入口點
@main
struct MedTakerApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationService = NotificationService.shared
    @State private var showNotificationPermission = false

    init() {
        // 應用啟動時的初始化設定
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .withThemeManager(themeManager)
                .onAppear {
                    checkNotificationPermission()
                }
                .sheet(isPresented: $showNotificationPermission) {
                    NotificationPermissionView()
                }
        }
    }

    /// 設定全局外觀
    private func setupAppearance() {
        // 可以在這裡設定全局的 UI 外觀
        // 例如：導航欄、Tab Bar 等的顏色
    }

    /// 檢查通知權限
    private func checkNotificationPermission() {
        // 延遲一下再檢查，讓 UI 先載入
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let hasSchedules = !DataPersistenceService.shared.fetchSchedules().isEmpty

            // 如果有排程但尚未請求通知權限，則顯示引導
            if hasSchedules &&
               !notificationService.hasRequestedPermission &&
               notificationService.authorizationStatus == .notDetermined {
                showNotificationPermission = true
            }
        }
    }
}
