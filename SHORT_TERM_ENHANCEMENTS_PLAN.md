# 短期功能擴展計劃 - MedTaker iOS

## 📋 計劃概述

本文檔詳細規劃了 MedTaker iOS App 的短期功能擴展（1-2 週內完成），包括三個主要功能：本地推送通知、深色模式優化和動畫效果增強。

---

## 🎯 功能清單

| 功能 | 優先級 | 預估時間 | 狀態 |
|------|--------|----------|------|
| 本地推送通知 | P0 | 2-3 天 | 🔄 進行中 |
| 深色模式優化 | P1 | 1-2 天 | ⏳ 待開始 |
| 動畫效果增強 | P1 | 1-2 天 | ⏳ 待開始 |

---

## 🔔 功能 1：本地推送通知

### 目標
實作完整的本地推送通知系統，在藥物排程時間到達前提醒使用者服藥。

### 功能需求

#### 1.1 通知權限管理
- 首次啟動時請求通知權限
- 優雅的權限引導 UI
- 權限拒絕後的提示和設定引導

#### 1.2 通知排程
- 根據藥物排程自動創建通知
- 支援每日重複通知
- 支援每週重複通知（特定星期）
- 提前 5 分鐘提醒（可配置）

#### 1.3 通知內容
- 標題：「服藥提醒」
- 內容：「{藥物名稱} - {劑量}」
- 副標題：預定時間
- 聲音和振動

#### 1.4 通知操作
- **已服用**：直接記錄服藥（以通知時間為實際時間）
- **稍後提醒**：延後 15 分鐘再次提醒
- **跳過**：標記為跳過

#### 1.5 通知管理
- 新增排程時自動創建通知
- 刪除排程時自動取消通知
- 更新排程時重新排程通知
- 停用排程時暫停通知

### 技術實作

#### NotificationService.swift
```swift
import UserNotifications
import Foundation

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var hasRequestedPermission = false

    private let center = UNUserNotificationCenter.current()

    // 功能：
    // - requestAuthorization() -> Bool
    // - scheduleNotification(for: MedicationSchedule)
    // - cancelNotification(id: String)
    // - updateNotifications(for schedules: [MedicationSchedule])
    // - rescheduleAllNotifications()
    // - handleNotificationAction(identifier: String, medicationId: String)
}
```

#### NotificationManager.swift
```swift
// 管理通知的生命週期
class NotificationManager: ObservableObject {
    // 與 ViewModel 整合
    // 監聽排程變更自動更新通知
}
```

#### 通知 Category 和 Action
```swift
// Category ID: "MEDICATION_REMINDER"
// Actions:
//   - "TAKE_ACTION" (前景)
//   - "SNOOZE_ACTION" (背景)
//   - "SKIP_ACTION" (背景)
```

### UI 實作

#### NotificationPermissionView.swift
```swift
// 通知權限請求引導頁面
// - 說明通知的好處
// - 清晰的圖示和文字
// - 請求權限按鈕
// - 稍後設定選項
```

#### NotificationSettingsView.swift
```swift
// 通知設定頁面（在 SettingsView 中）
// - 開啟/關閉通知總開關
// - 提前提醒時間設定（5/10/15/30 分鐘）
// - 通知聲音選擇
// - 前往系統設定的快捷方式
```

### 整合點

1. **App 啟動時**
   - 檢查通知權限狀態
   - 如果未決定，顯示引導頁面

2. **新增排程時**
   ```swift
   func addSchedule(_ schedule: MedicationSchedule) {
       // ... 現有邏輯
       NotificationService.shared.scheduleNotification(for: schedule)
   }
   ```

3. **刪除排程時**
   ```swift
   func deleteSchedule(_ schedule: MedicationSchedule) {
       // ... 現有邏輯
       NotificationService.shared.cancelNotification(id: schedule.id)
   }
   ```

4. **更新排程時**
   ```swift
   func updateSchedule(_ schedule: MedicationSchedule) {
       // ... 現有邏輯
       NotificationService.shared.cancelNotification(id: schedule.id)
       NotificationService.shared.scheduleNotification(for: schedule)
   }
   ```

### 測試要點
- ✅ 權限請求流程
- ✅ 通知準時觸發
- ✅ 通知內容正確
- ✅ 通知操作正確執行
- ✅ 排程變更時通知同步更新
- ✅ 每日/每週重複正確
- ✅ 時區處理正確

---

## 🌓 功能 2：深色模式優化

### 目標
完整支援 iOS 系統深色模式，提供舒適的夜間閱讀體驗。

### 功能需求

#### 2.1 顏色系統
- 定義完整的顏色主題
- 支援淺色/深色自動切換
- 保持視覺層次和對比度

#### 2.2 動態顏色
- 背景顏色（主背景、次背景、卡片）
- 文字顏色（主文字、次文字、提示）
- 強調顏色（主題色、成功、警告、錯誤）
- 分隔線和邊框

#### 2.3 圖示和插圖
- SF Symbols 自動適配
- 自訂圖示提供深色版本

### 技術實作

#### ColorTheme.swift
```swift
import SwiftUI

extension Color {
    // 背景顏色
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let backgroundTertiary = Color("BackgroundTertiary")

    // 文字顏色
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")

    // 強調顏色
    static let accentColor = Color("AccentColor")
    static let successColor = Color("SuccessColor")
    static let warningColor = Color("WarningColor")
    static let errorColor = Color("ErrorColor")

    // 狀態顏色（藥物狀態）
    static let statusOnTime = Color("StatusOnTime")
    static let statusLate = Color("StatusLate")
    static let statusMissed = Color("StatusMissed")
    static let statusSkipped = Color("StatusSkipped")
    static let statusUpcoming = Color("StatusUpcoming")
}
```

#### Assets.xcassets 顏色配置
```
Colors/
├── BackgroundPrimary
│   ├── Light: #FFFFFF
│   └── Dark: #000000
├── BackgroundSecondary
│   ├── Light: #F2F2F7
│   └── Dark: #1C1C1E
├── BackgroundTertiary
│   ├── Light: #FFFFFF
│   └── Dark: #2C2C2E
├── TextPrimary
│   ├── Light: #000000
│   └── Dark: #FFFFFF
├── TextSecondary
│   ├── Light: #3C3C43 (60%)
│   └── Dark: #EBEBF5 (60%)
...
```

#### ThemeManager.swift
```swift
import SwiftUI

class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme? = nil // nil = 跟隨系統

    enum Theme: String, CaseIterable {
        case system = "跟隨系統"
        case light = "淺色模式"
        case dark = "深色模式"
    }

    @Published var currentTheme: Theme = .system {
        didSet {
            updateColorScheme()
        }
    }

    private func updateColorScheme() {
        switch currentTheme {
        case .system: colorScheme = nil
        case .light: colorScheme = .light
        case .dark: colorScheme = .dark
        }
    }
}
```

### UI 更新

#### 需要更新的組件
1. **CalendarView**
   - 日期單元格背景
   - 選中狀態顏色
   - 狀態指示器顏色

2. **DailyMedicationView**
   - 卡片背景
   - 陰影效果
   - 統計卡片顏色

3. **MedicationScheduleListView**
   - 列表項背景
   - 分隔線顏色

4. **所有 Card 組件**
   - 統一使用動態背景色
   - 調整陰影適配深色模式

#### ThemeSettingsView.swift
```swift
// 在 SettingsView 中添加主題設定
struct ThemeSettingsView: View {
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        Section("外觀設定") {
            Picker("主題模式", selection: $themeManager.currentTheme) {
                ForEach(ThemeManager.Theme.allCases, id: \.self) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
        }
    }
}
```

### 測試要點
- ✅ 系統切換深色模式時應用自動更新
- ✅ 所有文字在深色背景下清晰可讀
- ✅ 顏色對比度符合 WCAG AA 標準
- ✅ 狀態顏色在深色模式下依然區分明確
- ✅ 陰影效果適配深色模式
- ✅ 圖示在深色模式下顯示正常

---

## ✨ 功能 3：動畫效果增強

### 目標
添加流暢的動畫和過渡效果，提升用戶體驗的愉悅感。

### 功能需求

#### 3.1 過渡動畫
- 頁面切換過渡
- Sheet 彈出動畫
- Alert 顯示動畫

#### 3.2 互動動畫
- 按鈕按下反饋
- 列表項點擊效果
- 開關切換動畫
- 拖動手勢動畫

#### 3.3 資料變更動畫
- 列表項新增/刪除
- 統計數字變化
- 狀態切換

#### 3.4 載入動畫
- 下拉刷新
- 載入指示器
- 骨架屏

### 技術實作

#### AnimationConstants.swift
```swift
import SwiftUI

struct AnimationConstants {
    // 動畫時長
    static let quick = 0.2
    static let normal = 0.3
    static let slow = 0.5

    // 彈簧動畫
    static let springResponse = 0.3
    static let springDamping = 0.7

    // 預設動畫
    static let `default` = Animation.easeInOut(duration: normal)
    static let spring = Animation.spring(response: springResponse, dampingFraction: springDamping)
    static let quickSpring = Animation.spring(response: 0.2, dampingFraction: 0.8)
}
```

#### 互動動畫修飾符
```swift
extension View {
    /// 按鈕按下縮放效果
    func pressableScale() -> some View {
        self.modifier(PressableScaleModifier())
    }

    /// 卡片點擊效果
    func cardTapAnimation() -> some View {
        self.modifier(CardTapModifier())
    }

    /// 淡入動畫
    func fadeIn(delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(delay: delay))
    }

    /// 滑入動畫
    func slideIn(edge: Edge = .bottom, delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(edge: edge, delay: delay))
    }
}

// 實作各種 ViewModifier
struct PressableScaleModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.quickSpring, value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

struct CardTapModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .animation(.quickSpring, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

struct SlideInModifier: ViewModifier {
    let edge: Edge
    let delay: Double
    @State private var offset: CGFloat = 50
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .offset(y: edge == .bottom ? offset : -offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}
```

#### LoadingView.swift
```swift
// 優雅的載入動畫
struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.blue, lineWidth: 4)
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)

            Text("載入中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
```

#### SkeletonView.swift
```swift
// 骨架屏載入效果
struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [.gray.opacity(0.3), .gray.opacity(0.1), .gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                }
            )
            .onAppear {
                isAnimating = true
            }
    }
}
```

### UI 更新位置

#### 1. CalendarView
```swift
// 日期單元格點擊動畫
DayCell(...)
    .cardTapAnimation()
    .transition(.scale.combined(with: .opacity))
```

#### 2. DailyMedicationView
```swift
// 藥物卡片出現動畫
ForEach(Array(viewModel.medications.enumerated()), id: \.element.id) { index, medication in
    MedicationCard(medication: medication)
        .slideIn(delay: Double(index) * 0.1)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
}
.animation(.spring(), value: viewModel.medications)

// 統計數字變化動畫
Text("\(statistics.total)")
    .contentTransition(.numericText())
    .animation(.default, value: statistics.total)
```

#### 3. MedicationScheduleListView
```swift
// 列表項動畫
ForEach(viewModel.schedules) { schedule in
    ScheduleCard(schedule: schedule)
        .cardTapAnimation()
}
.animation(.spring(), value: viewModel.schedules)
```

#### 4. 按鈕增強
```swift
Button("記錄服藥") {
    // action
}
.pressableScale()
```

#### 5. Sheet 動畫
```swift
.sheet(isPresented: $showSheet) {
    ContentView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

### 測試要點
- ✅ 動畫流暢（60fps）
- ✅ 無卡頓和延遲
- ✅ 動畫時長合理
- ✅ 不影響功能使用
- ✅ 低端設備表現正常
- ✅ 動畫可以中斷和覆蓋

---

## 🧪 測試計劃

### 測試環境
- iOS 16.0 模擬器
- iOS 17.0 模擬器
- iPhone SE (第三代) - 小螢幕測試
- iPhone 15 Pro Max - 大螢幕測試
- iPad Air - 平板測試

### 測試矩陣

| 功能 | 單元測試 | UI 測試 | 手動測試 | 狀態 |
|------|---------|---------|----------|------|
| 通知權限請求 | N/A | ✅ | ✅ | ⏳ |
| 通知排程創建 | ✅ | ✅ | ✅ | ⏳ |
| 通知觸發 | N/A | N/A | ✅ | ⏳ |
| 通知操作 | ✅ | N/A | ✅ | ⏳ |
| 深色模式切換 | N/A | ✅ | ✅ | ⏳ |
| 顏色對比度 | N/A | N/A | ✅ | ⏳ |
| 動畫流暢度 | N/A | N/A | ✅ | ⏳ |
| 性能測試 | N/A | N/A | ✅ | ⏳ |

### 單元測試

#### NotificationServiceTests.swift
```swift
class NotificationServiceTests: XCTestCase {
    func testScheduleNotification_Daily()
    func testScheduleNotification_Weekly()
    func testCancelNotification()
    func testUpdateNotifications()
    func testNotificationContent()
    func testNotificationTrigger()
}
```

#### ThemeManagerTests.swift
```swift
class ThemeManagerTests: XCTestCase {
    func testThemeSwitch()
    func testColorSchemeUpdate()
    func testPersistence()
}
```

### UI 測試

#### NotificationUITests.swift
```swift
func testNotificationPermissionFlow()
func testNotificationSettings()
```

#### ThemeUITests.swift
```swift
func testDarkModeSwitch()
func testColorAdaptation()
```

#### AnimationUITests.swift
```swift
func testButtonAnimation()
func testListAnimation()
```

### 手動測試檢查清單

#### 通知測試
- [ ] 首次啟動顯示權限引導
- [ ] 允許權限後通知正常創建
- [ ] 拒絕權限後顯示提示
- [ ] 通知在預定時間觸發
- [ ] 通知內容正確顯示
- [ ] 點擊通知開啟應用
- [ ] 「已服用」操作正確記錄
- [ ] 「稍後提醒」延後 15 分鐘
- [ ] 「跳過」標記為跳過狀態
- [ ] 每日通知每天重複
- [ ] 每週通知在正確日期觸發
- [ ] 新增排程自動創建通知
- [ ] 刪除排程自動取消通知
- [ ] 更新排程通知同步更新
- [ ] 停用排程暫停通知

#### 深色模式測試
- [ ] 系統切換時應用同步切換
- [ ] 手動切換主題正常
- [ ] 所有頁面適配深色模式
- [ ] 文字清晰可讀
- [ ] 顏色對比度足夠
- [ ] 狀態顏色區分明確
- [ ] 卡片陰影效果正常
- [ ] 圖示顯示正常
- [ ] 分隔線可見
- [ ] 按鈕狀態清楚

#### 動畫測試
- [ ] 頁面切換流暢
- [ ] Sheet 彈出自然
- [ ] 按鈕按下有反饋
- [ ] 列表項動畫流暢
- [ ] 數字變化有動畫
- [ ] 載入指示器正常
- [ ] 無卡頓現象
- [ ] 低端設備表現可接受
- [ ] 動畫不影響操作
- [ ] 快速操作不會卡死

### 性能測試
- [ ] 記憶體使用 < 150 MB
- [ ] CPU 使用率正常
- [ ] 電池消耗合理
- [ ] 通知不影響電量
- [ ] 動畫保持 60fps
- [ ] 應用啟動時間 < 3 秒

---

## 📅 實作時間表

### Week 1

**Day 1-2: 本地推送通知基礎**
- NotificationService 實作
- 權限請求流程
- 基礎通知排程

**Day 3: 通知進階功能**
- 通知操作實作
- 通知管理整合
- 單元測試

**Day 4: 深色模式**
- 顏色系統定義
- 主題管理器
- 所有 View 更新

**Day 5: 動畫效果**
- 動畫常數定義
- ViewModifier 實作
- 應用到各個 View

### Week 2

**Day 1-2: 整合測試**
- 功能測試
- UI 測試
- 手動測試

**Day 3: 優化和修正**
- Bug 修復
- 性能優化
- 細節打磨

**Day 4: 文檔和提交**
- 更新 README
- 撰寫使用指南
- Git 提交

---

## ✅ 完成標準

### 通知功能
- ✅ 通知權限流程完整
- ✅ 通知準時觸發
- ✅ 通知內容正確
- ✅ 通知操作正常工作
- ✅ 與排程管理完全整合
- ✅ 通過所有測試

### 深色模式
- ✅ 支援系統自動切換
- ✅ 手動切換功能
- ✅ 所有頁面完美適配
- ✅ 顏色對比度符合標準
- ✅ 視覺效果美觀

### 動畫效果
- ✅ 所有關鍵動畫實作
- ✅ 動畫流暢不卡頓
- ✅ 不影響應用性能
- ✅ 提升用戶體驗

---

## 🚀 後續計劃

完成短期功能後，即可進入中期計劃：
1. Widget 支持
2. Apple Watch 版本
3. HealthKit 整合

---

**預計完成時間：1-2 週**
**目標品質：生產級別，可直接發布**
