import SwiftUI

/// 主視圖 - 使用 TabView 組織主要功能
struct ContentView: View {
    @StateObject private var scheduleViewModel = MedicationScheduleViewModel()
    @StateObject private var calendarViewModel = CalendarViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: 日曆視圖
            NavigationView {
                CalendarTabView(calendarViewModel: calendarViewModel)
            }
            .tabItem {
                Label("日曆", systemImage: "calendar")
            }
            .tag(0)

            // Tab 2: 藥物排程
            NavigationView {
                MedicationScheduleListView(viewModel: scheduleViewModel)
            }
            .tabItem {
                Label("排程", systemImage: "pills.fill")
            }
            .tag(1)

            // Tab 3: 設定
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gear")
            }
            .tag(2)
        }
        .accentColor(.blue)
    }
}

/// 日曆頁籤視圖
struct CalendarTabView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @State private var showDailyView = false

    var body: some View {
        VStack(spacing: 0) {
            CalendarView(viewModel: calendarViewModel) { date in
                calendarViewModel.selectDate(date)
                showDailyView = true
            }
            .padding()

            Spacer()
        }
        .navigationTitle("服藥追蹤")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showDailyView) {
            NavigationView {
                DailyMedicationView(date: calendarViewModel.selectedDate) {
                    // 當藥物記錄更新時，重新載入日曆月份資料
                    calendarViewModel.loadMonth(calendarViewModel.currentMonth)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
