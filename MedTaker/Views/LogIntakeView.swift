import SwiftUI

/// 記錄服藥視圖
struct LogIntakeView: View {
    @Environment(\.dismiss) var dismiss
    let medication: DailyMedicationRecord
    let onConfirm: (Date, String) -> Void

    @State private var actualTime = Date()
    @State private var notes = ""

    var body: some View {
        Form {
                // 藥物資訊
                Section {
                    HStack {
                        Text("藥物名稱")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(medication.medicationName)
                            .bold()
                    }

                    HStack {
                        Text("劑量")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(medication.dosage)
                            .bold()
                    }
                } header: {
                    Text("藥物資訊")
                }

                // 時間資訊
                Section {
                    HStack {
                        Text("預定時間")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(medication.scheduledTime, style: .time)
                            .bold()
                            .foregroundColor(.blue)
                    }

                    DatePicker(
                        "實際服用時間",
                        selection: $actualTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } header: {
                    Text("時間")
                } footer: {
                    timeDifferenceFooter
                }

                // 備註
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                } header: {
                    Text("備註（選填）")
                }
        }
        .navigationTitle("記錄服藥")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("確認") {
                    onConfirm(actualTime, notes)
                    dismiss()
                }
            }
        }
        .onAppear {
            // 預設為當前時間
            actualTime = Date()
        }
    }

    // MARK: - 時間差提示

    @ViewBuilder
    private var timeDifferenceFooter: some View {
        let dateService = DateService.shared
        let isOnTime = dateService.isOnTime(scheduled: medication.scheduledTime, actual: actualTime)
        let timeDiff = dateService.formatTimeDifference(scheduled: medication.scheduledTime, actual: actualTime)

        HStack(spacing: 4) {
            Image(systemName: isOnTime ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isOnTime ? .green : .yellow)

            Text(timeDiff)
                .foregroundColor(isOnTime ? .green : .yellow)
        }
        .font(.caption)
    }
}

#Preview {
    LogIntakeView(
        medication: DailyMedicationRecord(
            scheduleId: "1",
            medicationName: "測試藥物",
            dosage: "10mg",
            scheduledTime: Date(),
            date: Date()
        )
    ) { _, _ in }
}
