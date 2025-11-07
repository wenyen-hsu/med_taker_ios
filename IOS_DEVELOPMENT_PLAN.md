# iOS App 開發計劃 - 服藥追蹤系統

## 📱 專案概述

將現有的 React Web 應用轉換為原生 Swift iOS 應用，保留所有核心功能並優化移動端用戶體驗。

---

## 🎯 開發目標

### 功能對應
| Web 功能 | iOS 實現 | 優先級 |
|---------|---------|--------|
| 藥物排程管理 | SwiftUI Forms + Core Data | P0 |
| 用藥記錄追蹤 | Interactive List + Notifications | P0 |
| 月曆視圖 | FSCalendar / Custom Calendar | P0 |
| 每日追蹤視圖 | List View with Statistics | P0 |
| 資料同步 | Supabase Swift SDK | P1 |
| 本地通知 | UNUserNotificationCenter | P1 |
| Widget 支持 | WidgetKit | P2 |

---

## 🏗️ 架構設計

### MVVM 架構模式

```
MedTaker (iOS App)
├── Models/              # 資料模型
│   ├── MedicationSchedule.swift
│   ├── DailyMedicationRecord.swift
│   └── MedicationStatus.swift
├── ViewModels/          # 業務邏輯
│   ├── MedicationScheduleViewModel.swift
│   ├── CalendarViewModel.swift
│   └── DailyMedicationViewModel.swift
├── Views/               # UI 層
│   ├── ContentView.swift (主要 TabView)
│   ├── CalendarView.swift
│   ├── DailyMedicationView.swift
│   ├── MedicationScheduleListView.swift
│   ├── AddMedicationView.swift
│   └── LogIntakeView.swift
├── Services/            # 服務層
│   ├── DataPersistenceService.swift (Core Data)
│   ├── SupabaseService.swift (API 調用)
│   ├── NotificationService.swift (本地通知)
│   └── DateService.swift (日期計算)
└── Utilities/           # 工具類
    ├── Extensions.swift
    ├── Constants.swift
    └── Helpers.swift
```

### 資料流程

```
View (SwiftUI)
    ↕ Binding / @Published
ViewModel (ObservableObject)
    ↕ CRUD Operations
Service Layer
    ↕
Core Data ← → Supabase (Sync)
```

---

## 📋 開發流程 (Phased Approach)

### Phase 1: 專案初始化與基礎架構 (第 1 天)

**1.1 建立 Xcode 專案**
- 建立新的 iOS App 專案
- 命名: MedTaker
- 最低支援版本: iOS 16.0
- 使用 SwiftUI + Swift 6.0
- 啟用 Core Data

**1.2 專案結構設置**
- 建立資料夾結構 (Models, Views, ViewModels, Services)
- 設定 Info.plist 權限（通知、背景執行）
- 配置 SwiftLint (可選)

**1.3 依賴管理**
```swift
// Package Dependencies (Swift Package Manager)
- Supabase Swift SDK
- FSCalendar (或使用原生 DatePicker)
```

**交付物:**
- ✅ 可運行的空白專案
- ✅ 資料夾結構完整
- ✅ 基礎配置完成

---

### Phase 2: 資料層實現 (第 2-3 天)

**2.1 定義資料模型**

```swift
// MedicationSchedule.swift
struct MedicationSchedule: Identifiable, Codable {
    let id: String
    var name: String
    var dosage: String
    var scheduledTime: Date
    var frequency: Frequency
    var activeDays: [Int]?
    var startDate: Date
    var endDate: Date?
    var isActive: Bool

    enum Frequency: String, Codable {
        case daily, weekly, custom
    }
}

// DailyMedicationRecord.swift
struct DailyMedicationRecord: Identifiable, Codable {
    let id: String
    let scheduleId: String
    var medicationName: String
    var dosage: String
    var scheduledTime: Date
    var date: Date
    var status: MedicationStatus
    var actualTime: Date?
    var notes: String?
}

// MedicationStatus.swift
enum MedicationStatus: String, Codable {
    case upcoming
    case onTime = "on-time"
    case late
    case missed
    case skipped

    var color: Color {
        switch self {
        case .upcoming: return .gray
        case .onTime: return .green
        case .late: return .yellow
        case .missed: return .red
        case .skipped: return .orange
        }
    }
}
```

**2.2 Core Data 實現**

```swift
// Core Data Entity: MedicationScheduleEntity, DailyRecordEntity
// DataPersistenceService.swift - CRUD operations
class DataPersistenceService {
    static let shared = DataPersistenceService()
    private let container: NSPersistentContainer

    func saveSchedule(_ schedule: MedicationSchedule) { }
    func fetchSchedules() -> [MedicationSchedule] { }
    func deleteSchedule(id: String) { }

    func saveDailyRecord(_ record: DailyMedicationRecord) { }
    func fetchRecords(for date: Date) -> [DailyMedicationRecord] { }
    func fetchRecords(from: Date, to: Date) -> [DailyMedicationRecord] { }
}
```

**2.3 日期服務**

```swift
// DateService.swift
class DateService {
    static func isOnTime(scheduled: Date, actual: Date) -> Bool {
        let diff = Calendar.current.dateComponents([.minute], from: scheduled, to: actual)
        return abs(diff.minute ?? 0) <= 15
    }

    static func shouldGenerateMedication(schedule: MedicationSchedule, for date: Date) -> Bool {
        // 實現排程邏輯判定
    }

    static func generateDailyRecords(for date: Date, schedules: [MedicationSchedule]) -> [DailyMedicationRecord] {
        // 根據排程生成每日記錄
    }
}
```

**交付物:**
- ✅ 完整的資料模型定義
- ✅ Core Data 持久化實現
- ✅ 日期計算邏輯
- ✅ 單元測試（資料層）

---

### Phase 3: 核心 UI 實現 (第 4-6 天)

**3.1 主界面框架**

```swift
// ContentView.swift
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem {
                    Label("日曆", systemImage: "calendar")
                }
                .tag(0)

            MedicationScheduleListView()
                .tabItem {
                    Label("排程", systemImage: "pills")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(2)
        }
    }
}
```

**3.2 日曆視圖**

```swift
// CalendarViewModel.swift
class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var monthRecords: [Date: DailyStats] = [:]
    @Published var isLoading = false

    func loadMonth(_ date: Date) async { }
    func getStatus(for date: Date) -> DayStatus { }
}

// CalendarView.swift
struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()

    var body: some View {
        VStack {
            // 月份選擇器
            MonthPickerView(selectedMonth: $viewModel.selectedDate)

            // 日曆網格
            CalendarGridView(
                month: viewModel.selectedDate,
                records: viewModel.monthRecords,
                onDateTap: { date in
                    viewModel.selectedDate = date
                    // 導航到每日視圖
                }
            )

            // 狀態說明
            StatusLegendView()
        }
        .navigationTitle("服藥追蹤")
        .task {
            await viewModel.loadMonth(viewModel.selectedDate)
        }
    }
}
```

**3.3 每日藥物視圖**

```swift
// DailyMedicationViewModel.swift
class DailyMedicationViewModel: ObservableObject {
    @Published var medications: [DailyMedicationRecord] = []
    @Published var statistics: DailyStatistics = .empty
    @Published var selectedDate: Date

    func loadMedications() async { }
    func logIntake(id: String, actualTime: Date, notes: String?) async { }
    func markAsSkipped(id: String) async { }
    func cancelRecord(id: String) async { }
}

// DailyMedicationView.swift
struct DailyMedicationView: View {
    @StateObject private var viewModel: DailyMedicationViewModel

    var body: some View {
        VStack {
            // 日期標題
            DateHeaderView(date: viewModel.selectedDate)

            // 統計卡片
            StatisticsCardView(stats: viewModel.statistics)

            // 藥物列表
            List(viewModel.medications) { medication in
                MedicationRowView(medication: medication) {
                    // 操作按鈕
                }
            }
        }
    }
}
```

**3.4 新增藥物視圖**

```swift
// AddMedicationView.swift
struct AddMedicationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var dosage = ""
    @State private var scheduledTime = Date()
    @State private var frequency = Frequency.daily
    @State private var activeDays: Set<Int> = []
    @State private var startDate = Date()
    @State private var endDate: Date?

    var body: some View {
        NavigationView {
            Form {
                Section("藥物資訊") {
                    TextField("藥物名稱", text: $name)
                    TextField("劑量", text: $dosage)
                }

                Section("服用時間") {
                    DatePicker("預定時間", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                }

                Section("頻率") {
                    Picker("頻率", selection: $frequency) {
                        Text("每日").tag(Frequency.daily)
                        Text("每週").tag(Frequency.weekly)
                    }

                    if frequency == .weekly {
                        WeekdayPicker(selectedDays: $activeDays)
                    }
                }

                Section("日期範圍") {
                    DatePicker("開始日期", selection: $startDate, displayedComponents: .date)
                    Toggle("設定結束日期", isOn: .constant(endDate != nil))
                    if endDate != nil {
                        DatePicker("結束日期", selection: Binding($endDate)!, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("新增藥物排程")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        // 儲存邏輯
                        dismiss()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
}
```

**3.5 記錄服藥對話框**

```swift
// LogIntakeView.swift
struct LogIntakeView: View {
    @Environment(\.dismiss) var dismiss
    let medication: DailyMedicationRecord
    @State private var actualTime = Date()
    @State private var notes = ""
    let onConfirm: (Date, String) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("預定時間") {
                    Text(medication.scheduledTime, style: .time)
                        .foregroundStyle(.secondary)
                }

                Section("實際服用時間") {
                    DatePicker("時間", selection: $actualTime, displayedComponents: [.date, .hourAndMinute])
                }

                Section("備註（選填）") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("記錄服藥")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確認") {
                        onConfirm(actualTime, notes)
                        dismiss()
                    }
                }
            }
        }
    }
}
```

**交付物:**
- ✅ 完整的 UI 界面
- ✅ 所有視圖和視圖模型
- ✅ 導航流程正確
- ✅ 基本交互功能

---

### Phase 4: Supabase 整合 (第 7-8 天)

**4.1 Supabase 服務層**

```swift
// SupabaseService.swift
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    private let client: SupabaseClient
    private let apiBaseURL: String
    private let publicAnonKey: String

    init() {
        self.publicAnonKey = "eyJhbGc..." // 從現有配置複製
        self.apiBaseURL = "https://yrfxmlzgczwrcxepqegp.supabase.co/functions/v1/make-server-3d52a703"
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://yrfxmlzgczwrcxepqegp.supabase.co")!,
            supabaseKey: publicAnonKey
        )
    }

    // MARK: - Schedules
    func fetchSchedules() async throws -> [MedicationSchedule] { }
    func addSchedule(_ schedule: MedicationSchedule) async throws { }
    func updateSchedule(_ schedule: MedicationSchedule) async throws { }
    func deleteSchedule(id: String) async throws { }

    // MARK: - Daily Records
    func fetchDailyRecords(for date: Date) async throws -> [DailyMedicationRecord] { }
    func fetchRecordsRange(from: Date, to: Date) async throws -> [DailyMedicationRecord] { }
    func updateRecord(_ record: DailyMedicationRecord) async throws { }
    func deleteRecord(id: String) async throws { }
    func resetAllRecords() async throws -> Int { }
}
```

**4.2 同步策略**

```swift
// SyncService.swift
class SyncService {
    static let shared = SyncService()

    private let persistence = DataPersistenceService.shared
    private let api = SupabaseService.shared

    // 離線優先策略
    func syncSchedules() async {
        // 1. 從 Core Data 讀取本地數據
        // 2. 從 Supabase 拉取遠端數據
        // 3. 合併衝突（使用時間戳）
        // 4. 更新本地和遠端
    }

    func syncRecords(for date: Date) async {
        // 類似邏輯
    }
}
```

**交付物:**
- ✅ Supabase SDK 整合
- ✅ API 調用層實現
- ✅ 離線支持
- ✅ 同步機制

---

### Phase 5: 通知功能 (第 9 天)

**5.1 通知服務**

```swift
// NotificationService.swift
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    func scheduleNotification(for schedule: MedicationSchedule) {
        let content = UNMutableNotificationContent()
        content.title = "服藥提醒"
        content.body = "\(schedule.name) - \(schedule.dosage)"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        // 根據排程時間創建觸發器
        let trigger = createTrigger(from: schedule)

        let request = UNNotificationRequest(
            identifier: schedule.id,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func updateNotifications(for schedules: [MedicationSchedule]) {
        // 取消所有舊通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // 重新排程活動的藥物
        for schedule in schedules where schedule.isActive {
            scheduleNotification(for: schedule)
        }
    }
}
```

**5.2 通知操作**

```swift
// AppDelegate.swift (或在 App struct 中處理)
extension UNUserNotificationCenter {
    func setupCategories() {
        let takeAction = UNNotificationAction(
            identifier: "TAKE_ACTION",
            title: "已服用",
            options: .foreground
        )

        let skipAction = UNNotificationAction(
            identifier: "SKIP_ACTION",
            title: "跳過",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [takeAction, skipAction],
            intentIdentifiers: []
        )

        setNotificationCategories([category])
    }
}
```

**交付物:**
- ✅ 本地通知實現
- ✅ 通知權限處理
- ✅ 通知操作支持

---

### Phase 6: Widget 擴展（可選，第 10 天）

```swift
// MedTakerWidget/MedTakerWidget.swift
import WidgetKit
import SwiftUI

struct TodayMedicationsWidget: Widget {
    let kind: String = "TodayMedicationsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayMedicationsEntryView(entry: entry)
        }
        .configurationDisplayName("今日服藥")
        .description("顯示今日待服用的藥物")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayMedicationsEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("今日服藥")
                .font(.headline)

            ForEach(entry.medications.prefix(3)) { med in
                HStack {
                    Image(systemName: "pills.fill")
                    VStack(alignment: .leading) {
                        Text(med.medicationName)
                        Text(med.scheduledTime, style: .time)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}
```

---

## 🧪 測試計劃

### 單元測試 (Unit Tests)

```swift
// MedTakerTests/DateServiceTests.swift
class DateServiceTests: XCTestCase {
    func testIsOnTime_WithinTolerance_ReturnsTrue() {
        let scheduled = Date()
        let actual = scheduled.addingTimeInterval(10 * 60) // +10 分鐘
        XCTAssertTrue(DateService.isOnTime(scheduled: scheduled, actual: actual))
    }

    func testIsOnTime_OutsideTolerance_ReturnsFalse() {
        let scheduled = Date()
        let actual = scheduled.addingTimeInterval(20 * 60) // +20 分鐘
        XCTAssertFalse(DateService.isOnTime(scheduled: scheduled, actual: actual))
    }

    func testShouldGenerateMedication_DailySchedule_ReturnsTrue() {
        // 測試每日排程邏輯
    }

    func testShouldGenerateMedication_WeeklySchedule_OnActiveDay_ReturnsTrue() {
        // 測試每週排程邏輯
    }
}

// DataPersistenceServiceTests.swift
class DataPersistenceServiceTests: XCTestCase {
    var service: DataPersistenceService!

    override func setUp() {
        super.setUp()
        service = DataPersistenceService(inMemory: true) // 使用內存存儲測試
    }

    func testSaveAndFetchSchedule() {
        let schedule = MedicationSchedule(
            id: UUID().uuidString,
            name: "Test Med",
            dosage: "10mg",
            scheduledTime: Date(),
            frequency: .daily,
            activeDays: nil,
            startDate: Date(),
            endDate: nil,
            isActive: true
        )

        service.saveSchedule(schedule)
        let fetched = service.fetchSchedules()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Test Med")
    }
}
```

### UI 測試 (UI Tests)

```swift
// MedTakerUITests/MedTakerUITests.swift
class MedTakerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAddMedicationFlow() {
        // 1. 點擊新增按鈕
        app.buttons["新增藥物排程"].tap()

        // 2. 填寫表單
        let nameField = app.textFields["藥物名稱"]
        nameField.tap()
        nameField.typeText("Aspirin")

        let dosageField = app.textFields["劑量"]
        dosageField.tap()
        dosageField.typeText("100mg")

        // 3. 儲存
        app.buttons["儲存"].tap()

        // 4. 驗證列表中出現
        XCTAssertTrue(app.staticTexts["Aspirin"].exists)
    }

    func testLogIntakeFlow() {
        // 測試記錄服藥流程
    }

    func testCalendarNavigation() {
        // 測試日曆導航
    }
}
```

### 整合測試

```swift
// IntegrationTests/SupabaseIntegrationTests.swift
class SupabaseIntegrationTests: XCTestCase {
    func testFetchSchedulesFromAPI() async throws {
        let service = SupabaseService.shared
        let schedules = try await service.fetchSchedules()
        XCTAssertNotNil(schedules)
    }

    func testSyncFlow() async throws {
        let syncService = SyncService.shared
        await syncService.syncSchedules()
        // 驗證同步結果
    }
}
```

### 手動測試檢查清單

**功能測試:**
- [ ] 新增藥物排程（每日/每週）
- [ ] 編輯藥物排程
- [ ] 刪除藥物排程
- [ ] 查看月曆視圖
- [ ] 點擊日期進入每日視圖
- [ ] 記錄服藥（準時）
- [ ] 記錄服藥（遲到）
- [ ] 標記跳過
- [ ] 取消記錄
- [ ] 修改記錄
- [ ] 查看統計數據
- [ ] 跨月份導航
- [ ] 通知權限請求
- [ ] 接收通知
- [ ] 通知操作（已服用/跳過）

**邊界測試:**
- [ ] 無網路連線時的操作
- [ ] 從離線恢復後的同步
- [ ] 跨時區處理
- [ ] 深夜邊界（23:59 → 00:00）
- [ ] 大量藥物排程（50+）
- [ ] 長期使用（跨年）
- [ ] 刪除所有數據後的狀態

**性能測試:**
- [ ] 啟動時間 < 2 秒
- [ ] 月曆切換流暢
- [ ] 列表滾動流暢（60 fps）
- [ ] 記憶體使用 < 100 MB

**可用性測試:**
- [ ] 深色模式支持
- [ ] 動態字型大小
- [ ] VoiceOver 導航
- [ ] 橫向/縱向旋轉
- [ ] 不同螢幕尺寸（iPhone SE, iPhone 15 Pro Max, iPad）

---

## 📱 技術規格

### 最低要求
- iOS 16.0+
- Swift 6.0
- Xcode 15+

### 依賴套件
```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
]
```

### 性能目標
- 冷啟動時間: < 2 秒
- 記憶體佔用: < 100 MB
- 電池影響: 最小化（背景工作）
- APK 大小: < 50 MB

---

## 🔄 持續改進計劃

### 後續功能（Post-MVP）
1. Apple Watch 擴展
2. Siri Shortcuts 支持
3. HealthKit 整合
4. 家庭共享功能
5. 藥物交互警告
6. 處方籤掃描（OCR）
7. 醫生/藥劑師備註
8. 多語言支持

### 優化方向
1. 離線優先策略增強
2. 資料同步衝突解決
3. 通知智能提醒（根據用戶習慣）
4. 機器學習預測遺漏風險
5. 動畫與過渡效果優化

---

## 📅 時間估算

| 階段 | 預估時間 | 累計 |
|------|---------|------|
| Phase 1: 專案初始化 | 0.5 天 | 0.5 天 |
| Phase 2: 資料層 | 1.5 天 | 2 天 |
| Phase 3: UI 實現 | 3 天 | 5 天 |
| Phase 4: Supabase 整合 | 2 天 | 7 天 |
| Phase 5: 通知功能 | 1 天 | 8 天 |
| Phase 6: Widget (可選) | 1 天 | 9 天 |
| 測試與修正 | 2 天 | 11 天 |
| 優化與打磨 | 1 天 | 12 天 |

**總預估: 12 個工作日 (約 2.5 週)**

---

## ✅ 驗收標準

### 必須滿足 (MVP)
- [x] 所有核心功能完整實現
- [x] 資料持久化正常運作
- [x] Supabase 同步功能正常
- [x] UI 符合 iOS 設計規範
- [x] 無嚴重 Bug
- [x] 通過所有單元測試
- [x] 通過所有 UI 測試
- [x] 手動測試檢查清單完成
- [x] 本地通知正常運作

### 加分項
- [ ] Widget 支持
- [ ] Apple Watch 支持
- [ ] 完整的錯誤處理和用戶反饋
- [ ] 優雅的動畫效果
- [ ] 無障礙支持完整

---

## 🚀 部署計劃

### TestFlight Beta
1. 建立 App Store Connect 記錄
2. 配置 TestFlight
3. 內部測試（1 週）
4. 外部測試（2 週）
5. 收集反饋並修正

### App Store 提交
1. 準備 App Store 素材
   - 截圖（所有螢幕尺寸）
   - 宣傳文案
   - 隱私政策
2. 提交審核
3. 上架

---

## 📞 風險與應對

| 風險 | 影響 | 機率 | 應對策略 |
|------|------|------|----------|
| Supabase API 變更 | 高 | 低 | 抽象化 API 層，易於替換 |
| 通知權限被拒 | 中 | 中 | 提供良好的引導說明，允許無通知使用 |
| Core Data 遷移問題 | 高 | 低 | 仔細規劃資料模型版本控制 |
| 性能問題（大量數據）| 中 | 中 | 分頁加載，資料庫索引優化 |
| iOS 版本更新不相容 | 中 | 中 | 持續追蹤 iOS 更新，及時適配 |

---

## 總結

本開發計劃提供了完整的路線圖，從基礎架構到最終部署。採用分階段開發策略，確保每個階段都有明確的交付物和驗證標準。通過 MVVM 架構、離線優先策略和完整的測試計劃，確保 iOS 應用的質量和可維護性。
