import SwiftUI

/// MedTaker iOS 應用程式入口點
@main
struct MedTakerApp: App {
    init() {
        // 應用啟動時的初始化設定
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    /// 設定全局外觀
    private func setupAppearance() {
        // 可以在這裡設定全局的 UI 外觀
        // 例如：導航欄、Tab Bar 等的顏色
    }
}
