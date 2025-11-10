import SwiftUI

/// 每日藥物追蹤視圖
struct DailyMedicationView: View {
    @StateObject private var viewModel: DailyMedicationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showLogDialog = false
    @State private var selectedMedication: DailyMedicationRecord?
    var onMedicationUpdated: (() -> Void)? = nil

    init(date: Date, onMedicationUpdated: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: DailyMedicationViewModel(date: date))
        self.onMedicationUpdated = onMedicationUpdated
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 日期標題
                dateHeader

                // 統計卡片
                statisticsCards

                // 藥物列表
                medicationList
            }
            .padding()
        }
        .navigationTitle("每日追蹤")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("關閉") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showLogDialog) {
            if let medication = selectedMedication {
                NavigationView {
                    LogIntakeView(medication: medication) { actualTime, notes in
                        viewModel.logIntake(id: medication.id, actualTime: actualTime, notes: notes)
                        // 通知日曆視圖更新
                        onMedicationUpdated?()
                    }
                }
            }
        }
        .alert("錯誤", isPresented: $viewModel.showError) {
            Button("確定", role: .cancel) { }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - 日期標題

    private var dateHeader: some View {
        VStack(spacing: 4) {
            Text(viewModel.dateTitle)
                .font(.title2.bold())

            HStack {
                Button(action: { viewModel.previousDay() }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                if !viewModel.isToday {
                    Button("回到今天") {
                        viewModel.goToToday()
                    }
                    .font(.caption)
                }

                Spacer()

                Button(action: { viewModel.nextDay() }) {
                    Image(systemName: "chevron.right")
                }
            }
            .font(.title3)
            .padding(.horizontal, 40)
        }
        .padding()
    }

    // MARK: - 統計卡片

    private var statisticsCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(title: "總計", value: "\(viewModel.statistics.total)", color: .blue)
                StatCard(
                    title: "完成率",
                    value: String(format: "%.0f%%", viewModel.statistics.completionRate),
                    color: .purple
                )
            }

            HStack(spacing: 12) {
                StatCard(title: "準時", value: "\(viewModel.statistics.onTime)", color: .green)
                StatCard(title: "遲到", value: "\(viewModel.statistics.late)", color: .yellow)
                StatCard(title: "錯過", value: "\(viewModel.statistics.missed)", color: .red)
            }
        }
    }

    // MARK: - 藥物列表

    private var medicationList: some View {
        VStack(spacing: 12) {
            if viewModel.medications.isEmpty {
                EmptyStateView()
            } else {
                ForEach(viewModel.medications) { medication in
                    MedicationCard(
                        medication: medication,
                        onLog: {
                            selectedMedication = medication
                            showLogDialog = true
                        },
                        onSkip: {
                            viewModel.markAsSkipped(id: medication.id)
                            // 通知日曆視圖更新
                            onMedicationUpdated?()
                        },
                        onCancel: {
                            viewModel.cancelRecord(id: medication.id)
                            // 通知日曆視圖更新
                            onMedicationUpdated?()
                        }
                    )
                }
            }
        }
    }
}

/// 統計卡片
struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// 藥物卡片
struct MedicationCard: View {
    let medication: DailyMedicationRecord
    let onLog: () -> Void
    let onSkip: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 頭部：名稱和狀態
            HStack {
                Image(systemName: medication.status.iconName)
                    .foregroundColor(medication.status.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.medicationName)
                        .font(.headline)

                    Text(medication.dosage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(medication.status.displayName)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(medication.status.color.opacity(0.2))
                    .foregroundColor(medication.status.color)
                    .cornerRadius(8)
            }

            // 時間資訊
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("預定時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(medication.scheduledTime, style: .time)
                        .font(.subheadline.bold())
                }

                if let actualTime = medication.actualTime {
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("實際時間")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(actualTime, style: .time)
                            .font(.subheadline.bold())
                            .foregroundColor(medication.status.color)
                    }
                }
            }

            // 備註
            if let notes = medication.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("備註")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.subheadline)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            // 操作按鈕
            actionButtons
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if medication.status == .upcoming {
            HStack(spacing: 12) {
                Button(action: onLog) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("記錄服藥")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button(action: onSkip) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("跳過")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        } else if medication.status.isCompleted {
            Button(action: onCancel) {
                HStack {
                    Image(systemName: "arrow.uturn.backward")
                    Text("取消記錄")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}

/// 空狀態視圖
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("今日無藥物排程")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("您可以在「排程」頁籤新增藥物排程")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

#Preview {
    NavigationView {
        DailyMedicationView(date: Date())
    }
}
