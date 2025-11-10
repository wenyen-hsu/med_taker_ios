import SwiftUI
import Combine

// MARK: - 顏色主題擴展

extension Color {
    // MARK: - 背景顏色

    /// 主背景色
    static let backgroundPrimary = Color("BackgroundPrimary", bundle: nil, fallback: Color(uiColor: .systemBackground))

    /// 次背景色
    static let backgroundSecondary = Color("BackgroundSecondary", bundle: nil, fallback: Color(uiColor: .secondarySystemBackground))

    /// 第三背景色
    static let backgroundTertiary = Color("BackgroundTertiary", bundle: nil, fallback: Color(uiColor: .tertiarySystemBackground))

    /// 分組背景色
    static let backgroundGrouped = Color("BackgroundGrouped", bundle: nil, fallback: Color(uiColor: .systemGroupedBackground))

    // MARK: - 文字顏色

    /// 主文字顏色
    static let textPrimary = Color("TextPrimary", bundle: nil, fallback: Color(uiColor: .label))

    /// 次文字顏色
    static let textSecondary = Color("TextSecondary", bundle: nil, fallback: Color(uiColor: .secondaryLabel))

    /// 第三文字顏色
    static let textTertiary = Color("TextTertiary", bundle: nil, fallback: Color(uiColor: .tertiaryLabel))

    // MARK: - 強調顏色

    /// 主題強調色
    static let accentPrimary = Color("AccentPrimary", bundle: nil, fallback: .blue)

    /// 成功顏色
    static let successColor = Color("SuccessColor", bundle: nil, fallback: .green)

    /// 警告顏色
    static let warningColor = Color("WarningColor", bundle: nil, fallback: .yellow)

    /// 錯誤顏色
    static let errorColor = Color("ErrorColor", bundle: nil, fallback: .red)

    // MARK: - 藥物狀態顏色

    /// 準時狀態顏色
    static let statusOnTime = Color("StatusOnTime", bundle: nil, fallback: .green)

    /// 遲到狀態顏色
    static let statusLate = Color("StatusLate", bundle: nil, fallback: .yellow)

    /// 錯過狀態顏色
    static let statusMissed = Color("StatusMissed", bundle: nil, fallback: .red)

    /// 跳過狀態顏色
    static let statusSkipped = Color("StatusSkipped", bundle: nil, fallback: .orange)

    /// 待服用狀態顏色
    static let statusUpcoming = Color("StatusUpcoming", bundle: nil, fallback: .gray)

    // MARK: - 卡片與容器顏色

    /// 卡片背景色
    static let cardBackground = Color("CardBackground", bundle: nil, fallback: Color(uiColor: .systemBackground))

    /// 卡片陰影色
    static let cardShadow = Color("CardShadow", bundle: nil, fallback: Color.black.opacity(0.1))

    // MARK: - 分隔線顏色

    /// 分隔線顏色
    static let separatorColor = Color("SeparatorColor", bundle: nil, fallback: Color(uiColor: .separator))

    // MARK: - 建構函式（支援 fallback）

    init(_ name: String, bundle: Bundle?, fallback: Color) {
        if let color = UIColor(named: name, in: bundle, compatibleWith: nil) {
            self.init(uiColor: color)
        } else {
            self = fallback
        }
    }
}

// MARK: - 主題管理器

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    /// 主題模式
    enum Theme: String, CaseIterable, Identifiable {
        case system = "跟隨系統"
        case light = "淺色模式"
        case dark = "深色模式"

        var id: String { rawValue }
    }

    @Published var currentTheme: Theme {
        didSet {
            updateColorScheme()
            saveTheme()
        }
    }

    @Published var colorScheme: ColorScheme?

    private let userDefaults = UserDefaults.standard
    private let themeKey = "app_theme"

    init() {
        // 從 UserDefaults 載入保存的主題
        if let savedTheme = userDefaults.string(forKey: themeKey),
           let theme = Theme(rawValue: savedTheme) {
            currentTheme = theme
        } else {
            currentTheme = .system
        }

        updateColorScheme()
    }

    /// 更新顏色方案
    private func updateColorScheme() {
        switch currentTheme {
        case .system:
            colorScheme = nil
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
    }

    /// 保存主題設定
    private func saveTheme() {
        userDefaults.set(currentTheme.rawValue, forKey: themeKey)
    }

    /// 設定主題
    func setTheme(_ theme: Theme) {
        currentTheme = theme
    }

    /// 是否為深色模式
    var isDarkMode: Bool {
        switch currentTheme {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
}

// MARK: - 環境值擴展

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View 擴展

extension View {
    /// 應用主題管理器
    func withThemeManager(_ manager: ThemeManager) -> some View {
        self.environment(\.themeManager, manager)
            .preferredColorScheme(manager.colorScheme)
    }

    /// 應用共享主題管理器
    @MainActor
    func withSharedThemeManager() -> some View {
        self.environment(\.themeManager, ThemeManager.shared)
            .preferredColorScheme(ThemeManager.shared.colorScheme)
    }
}
