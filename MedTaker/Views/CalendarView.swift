import SwiftUI

/// 日曆視圖組件
struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let onDateSelected: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 16) {
            // 月份導航
            monthNavigationBar

            // 星期標題
            weekdayHeader

            // 日曆網格
            calendarGrid

            // 狀態說明
            statusLegend

            if viewModel.isLoading {
                ProgressView("載入中...")
                    .padding()
            }
        }
    }

    // MARK: - 月份導航列

    private var monthNavigationBar: some View {
        HStack {
            Button(action: { viewModel.previousMonth() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(.title2.bold())

            Spacer()

            Button(action: { viewModel.nextMonth() }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 星期標題

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 日曆網格

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(daysInMonth(), id: \.self) { date in
                if let date = date {
                    DayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isToday: date.isToday,
                        color: viewModel.colorForDate(date),
                        statistics: viewModel.statisticsForDate(date)
                    )
                    .onTapGesture {
                        onDateSelected(date)
                    }
                } else {
                    Color.clear
                        .frame(height: 50)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 狀態說明

    private var statusLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("狀態說明")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                LegendItem(color: .green, text: "全部準時")
                LegendItem(color: .yellow, text: "有遲到")
                LegendItem(color: .orange, text: "部分完成")
                LegendItem(color: .red, text: "未完成")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - 輔助方法

    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let month = viewModel.currentMonth
        let startOfMonth = month.startOfMonth()

        // 計算月份第一天是星期幾
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1

        // 計算月份有多少天
        let range = calendar.range(of: .day, in: .month, for: month)!
        let numberOfDays = range.count

        // 創建日期陣列
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) {
                days.append(date)
            }
        }

        return days
    }
}

/// 日期單元格
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let color: Color?
    let statistics: DailyStatistics?

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))

            if let color = color {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

/// 圖例項目
struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CalendarView(viewModel: CalendarViewModel()) { _ in }
}
