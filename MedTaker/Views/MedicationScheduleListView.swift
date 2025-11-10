import SwiftUI

/// 藥物排程列表視圖
struct MedicationScheduleListView: View {
    @ObservedObject var viewModel: MedicationScheduleViewModel
    @State private var showAddSheet = false
    @State private var showDeleteAlert = false
    @State private var scheduleToDelete: MedicationSchedule?
    var onSchedulesChanged: (() -> Void)? = nil

    init(viewModel: MedicationScheduleViewModel, onSchedulesChanged: (() -> Void)? = nil) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.onSchedulesChanged = onSchedulesChanged
    }

    var body: some View {
        ZStack {
            if viewModel.schedules.isEmpty {
                emptyStateView
            } else {
                scheduleList
            }
        }
        .navigationTitle("藥物排程")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddMedicationView { schedule in
                viewModel.addSchedule(schedule)
                onSchedulesChanged?()
            }
        }
        .alert("確認刪除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                if let schedule = scheduleToDelete {
                    viewModel.deleteSchedule(schedule)
                    onSchedulesChanged?()
                }
            }
        } message: {
            Text("確定要刪除這個藥物排程嗎？")
        }
        .alert("錯誤", isPresented: $viewModel.showError) {
            Button("確定", role: .cancel) { }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - 排程列表

    private var scheduleList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.schedules) { schedule in
                    ScheduleCard(
                        schedule: schedule,
                        onToggleActive: {
                            viewModel.toggleScheduleActive(schedule)
                            onSchedulesChanged?()
                        },
                        onDelete: {
                            scheduleToDelete = schedule
                            showDeleteAlert = true
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - 空狀態視圖

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("尚無藥物排程")
                .font(.title2.bold())

            Text("點擊右上角的 + 按鈕\n新增您的第一個藥物排程")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showAddSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("新增排程")
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.top)
        }
        .padding()
    }
}

/// 排程卡片
struct ScheduleCard: View {
    let schedule: MedicationSchedule
    let onToggleActive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 頭部：名稱和開關
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.name)
                        .font(.headline)

                    Text(schedule.dosage)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { schedule.isActive },
                    set: { _ in onToggleActive() }
                ))
                .labelsHidden()
            }

            Divider()

            // 服用時間
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                    .font(.caption)

                Text("服用時間：")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(schedule.scheduledTime, style: .time)
                    .font(.subheadline.bold())
            }

            // 頻率資訊
            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(.purple)
                    .font(.caption)

                Text("頻率：")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(frequencyText)
                    .font(.subheadline.bold())
            }

            // 開始日期
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.green)
                    .font(.caption)

                Text("開始：")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(schedule.startDate, style: .date)
                    .font(.subheadline.bold())

                if let endDate = schedule.endDate {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text(endDate, style: .date)
                        .font(.subheadline.bold())
                }
            }

            // 刪除按鈕
            Button(action: onDelete) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("刪除排程")
                }
                .font(.caption.bold())
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .opacity(schedule.isActive ? 1.0 : 0.5)
    }

    private var frequencyText: String {
        switch schedule.frequency {
        case .daily:
            return "每日"
        case .weekly:
            if let activeDays = schedule.activeDays {
                let weekdayNames = ["日", "一", "二", "三", "四", "五", "六"]
                let days = activeDays.map { weekdayNames[$0] }.joined(separator: ", ")
                return "每週：\(days)"
            }
            return "每週"
        case .custom:
            return "自訂"
        }
    }
}

#Preview {
    NavigationView {
        MedicationScheduleListView(viewModel: MedicationScheduleViewModel())
    }
}
