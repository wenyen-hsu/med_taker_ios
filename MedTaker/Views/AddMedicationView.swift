import SwiftUI

/// 新增藥物排程視圖
struct AddMedicationView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (MedicationSchedule) -> Void

    // 表單狀態
    @State private var name = ""
    @State private var dosage = ""
    @State private var scheduledTime = Date()
    @State private var frequency: MedicationSchedule.Frequency = .daily
    @State private var selectedDays: Set<Int> = []
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()

    // 驗證
    private var isValid: Bool {
        !name.isEmpty && !dosage.isEmpty &&
        (frequency != .weekly || !selectedDays.isEmpty)
    }

    var body: some View {
        NavigationView {
            Form {
                // 藥物資訊
                Section {
                    TextField("藥物名稱", text: $name)
                        .autocorrectionDisabled()

                    TextField("劑量（例如：10mg）", text: $dosage)
                        .autocorrectionDisabled()
                } header: {
                    Text("藥物資訊")
                }

                // 服用時間
                Section {
                    DatePicker(
                        "預定時間",
                        selection: $scheduledTime,
                        displayedComponents: [.hourAndMinute]
                    )
                } header: {
                    Text("服用時間")
                }

                // 頻率設定
                Section {
                    Picker("頻率", selection: $frequency) {
                        ForEach(MedicationSchedule.Frequency.allCases.filter { $0 != .custom }, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)

                    if frequency == .weekly {
                        WeekdaySelector(selectedDays: $selectedDays)
                    }
                } header: {
                    Text("頻率")
                } footer: {
                    if frequency == .weekly && selectedDays.isEmpty {
                        Text("請至少選擇一天")
                            .foregroundColor(.red)
                    }
                }

                // 日期範圍
                Section {
                    DatePicker(
                        "開始日期",
                        selection: $startDate,
                        displayedComponents: [.date]
                    )

                    Toggle("設定結束日期", isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker(
                            "結束日期",
                            selection: $endDate,
                            in: startDate...,
                            displayedComponents: [.date]
                        )
                    }
                } header: {
                    Text("日期範圍")
                }
            }
            .navigationTitle("新增藥物排程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        saveSchedule()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func saveSchedule() {
        let schedule = MedicationSchedule(
            name: name,
            dosage: dosage,
            scheduledTime: scheduledTime,
            frequency: frequency,
            activeDays: frequency == .weekly ? Array(selectedDays) : nil,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            isActive: true
        )

        onSave(schedule)
        dismiss()
    }
}

/// 星期選擇器
struct WeekdaySelector: View {
    @Binding var selectedDays: Set<Int>

    private let weekdays = [
        (0, "日"),
        (1, "一"),
        (2, "二"),
        (3, "三"),
        (4, "四"),
        (5, "五"),
        (6, "六")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇服用日")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdays, id: \.0) { day, label in
                    WeekdayButton(
                        label: label,
                        isSelected: selectedDays.contains(day)
                    ) {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

/// 星期按鈕
struct WeekdayButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
    }
}

#Preview {
    AddMedicationView { _ in }
}
