# MedTaker - 服藥追蹤 iOS App

## 📱 專案簡介

MedTaker 是一個原生 iOS 應用程式，用於追蹤和管理您的日常用藥。本專案從 React Web 應用轉換而來，保留了所有核心功能並針對 iOS 平台進行了優化。

### 主要功能

- ✅ **藥物排程管理**：新增、編輯和刪除藥物排程
- 📅 **互動式日曆**：視覺化顯示每月服藥完成情況
- 📊 **每日追蹤**：詳細的每日用藥記錄和統計
- ⏰ **準時判定**：自動判斷服藥是否準時（±15 分鐘）
- 🔄 **資料同步**：與 Supabase 後端服務同步
- 📱 **離線支持**：本地資料儲存，無網路也能使用

## 🏗️ 專案結構

```
MedTaker/
├── Models/                     # 資料模型
│   ├── MedicationSchedule.swift
│   ├── DailyMedicationRecord.swift
│   └── MedicationStatus.swift
├── ViewModels/                 # 視圖模型（MVVM）
│   ├── MedicationScheduleViewModel.swift
│   ├── CalendarViewModel.swift
│   └── DailyMedicationViewModel.swift
├── Views/                      # UI 視圖
│   ├── ContentView.swift
│   ├── CalendarView.swift
│   ├── DailyMedicationView.swift
│   ├── MedicationScheduleListView.swift
│   ├── AddMedicationView.swift
│   ├── LogIntakeView.swift
│   └── SettingsView.swift
├── Services/                   # 服務層
│   ├── DataPersistenceService.swift
│   ├── SupabaseService.swift
│   └── DateService.swift
├── Utilities/                  # 工具類
│   └── DateExtensions.swift
├── Tests/                      # 單元測試
│   ├── DateServiceTests.swift
│   ├── DataPersistenceServiceTests.swift
│   └── MedicationStatusTests.swift
├── MedTakerApp.swift          # App 入口點
└── Info.plist                 # 配置檔案
```

## 🎨 架構設計

本專案採用 **MVVM (Model-View-ViewModel)** 架構模式：

- **Models**：定義資料結構和業務實體
- **Views**：SwiftUI 視圖，負責 UI 呈現
- **ViewModels**：業務邏輯和狀態管理
- **Services**：資料持久化、API 調用等服務

### 資料流程

```
View (SwiftUI)
    ↕ @Published / Binding
ViewModel (ObservableObject)
    ↕ CRUD Operations
Service Layer
    ↕
UserDefaults ← → Supabase API
```

## 🚀 技術規格

- **最低支援版本**：iOS 16.0+
- **開發語言**：Swift 6.0
- **UI 框架**：SwiftUI
- **架構模式**：MVVM
- **資料持久化**：UserDefaults（可升級至 Core Data）
- **網路層**：URLSession + async/await
- **後端服務**：Supabase

## 📦 安裝與設定

### 前置需求

- Xcode 15.0 或以上
- macOS Sonoma 或以上
- iOS 16.0+ 測試裝置或模擬器

### 步驟

1. **Clone 專案**
   ```bash
   git clone <repository-url>
   cd med_taker_ios
   ```

2. **開啟 Xcode 專案**
   ```bash
   cd MedTaker
   # 在 Xcode 中開啟 MedTaker 資料夾
   ```

3. **配置 Supabase（選填）**

   如果您想使用自己的 Supabase 專案：

   在 `Services/SupabaseService.swift` 中更新：
   ```swift
   private let projectId = "YOUR_PROJECT_ID"
   private let publicAnonKey = "YOUR_ANON_KEY"
   ```

4. **建置並執行**

   - 選擇目標裝置或模擬器
   - 按下 Cmd+R 執行專案

## 🧪 測試

### 執行單元測試

在 Xcode 中：
- 按下 Cmd+U 執行所有測試
- 或在 Test Navigator (Cmd+6) 中選擇特定測試

### 測試覆蓋範圍

- ✅ DateService 測試（準時判定、排程生成等）
- ✅ DataPersistenceService 測試（CRUD 操作）
- ✅ MedicationStatus 測試（狀態和統計）

## 📖 使用指南

### 新增藥物排程

1. 切換到「排程」頁籤
2. 點擊右上角的 + 按鈕
3. 填寫藥物資訊：
   - 藥物名稱（例如：Lisinopril）
   - 劑量（例如：10mg）
   - 服用時間
   - 頻率（每日/每週）
   - 開始日期和結束日期（選填）
4. 點擊「儲存」

### 記錄服藥

1. 在「日曆」頁籤點擊日期，或直接查看今日藥物
2. 在藥物卡片上點擊「記錄服藥」
3. 確認或調整實際服用時間
4. 添加備註（選填）
5. 點擊「確認」

系統會自動判斷：
- **準時**：在預定時間 ±15 分鐘內
- **遲到**：超過 15 分鐘

### 查看統計

- **日曆視圖**：顏色指示每日完成情況
  - 🟢 綠色：全部準時
  - 🟡 黃色：全部完成但有遲到
  - 🟠 橙色：部分完成
  - 🔴 紅色：未完成

- **每日視圖**：顯示詳細統計
  - 總計
  - 完成率
  - 準時數、遲到數、錯過數

## 🔄 與 Web 版本的對應

| Web 功能 | iOS 實現 | 狀態 |
|---------|---------|------|
| 藥物排程管理 | MedicationScheduleListView | ✅ |
| 用藥記錄追蹤 | DailyMedicationView | ✅ |
| 月曆視圖 | CalendarView | ✅ |
| 每日統計 | DailyStatistics | ✅ |
| Supabase 同步 | SupabaseService | ✅ |
| 本地通知 | NotificationService | 🔄 待實現 |
| Widget | WidgetKit | 🔄 待實現 |

## 🐛 已知問題

目前沒有已知的嚴重問題。

## 🚧 待完成功能

- [ ] 本地推送通知
- [ ] Widget 擴展
- [ ] Apple Watch 支持
- [ ] HealthKit 整合
- [ ] Siri Shortcuts
- [ ] 深色模式完整優化

## 📝 API 文檔

### 核心資料模型

#### MedicationSchedule
```swift
struct MedicationSchedule {
    let id: String
    var name: String              // 藥物名稱
    var dosage: String            // 劑量
    var scheduledTime: Date       // 預定時間
    var frequency: Frequency      // 頻率（每日/每週）
    var activeDays: [Int]?        // 活動日（0-6）
    var startDate: Date           // 開始日期
    var endDate: Date?            // 結束日期
    var isActive: Bool            // 是否活動
}
```

#### DailyMedicationRecord
```swift
struct DailyMedicationRecord {
    let id: String
    let scheduleId: String
    var medicationName: String
    var dosage: String
    var scheduledTime: Date
    var date: Date
    var status: MedicationStatus  // 狀態
    var actualTime: Date?         // 實際時間
    var notes: String?            // 備註
}
```

#### MedicationStatus
```swift
enum MedicationStatus {
    case upcoming   // 待服用
    case onTime     // 準時
    case late       // 遲到
    case missed     // 錯過
    case skipped    // 跳過
}
```

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

## 📄 授權

本專案採用 MIT 授權。

## 👨‍💻 作者

由 Web 應用轉換而來，使用 Claude Code 協助開發。

## 🙏 致謝

- 原始 Web 應用的設計和功能
- Supabase 提供的後端服務
- SwiftUI 社群的支持

---

**版本**：1.0.0
**最後更新**：2025-11-07
