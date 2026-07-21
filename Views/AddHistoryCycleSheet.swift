import SwiftUI

/// 手动添加/编辑历史经期记录 Sheet (无专业术语，自然友好的极简界面)
public struct AddHistoryCycleSheet: View {
    @Environment(\.dismiss) private var dismiss

    let editingCycle: Cycle?
    let onSave: (Cycle) -> Void

    @State private var startDate: Date = Date()
    @State private var periodLength: Int = 5
    @State private var cycleLength: Int = 28
    @State private var isOutlier: Bool = false

    public init(editingCycle: Cycle? = nil, onSave: @escaping (Cycle) -> Void) {
        self.editingCycle = editingCycle
        self.onSave = onSave

        if let existing = editingCycle {
            _startDate = State(initialValue: existing.startDate)
            _periodLength = State(initialValue: existing.periodLength ?? 5)
            _cycleLength = State(initialValue: existing.cycleLength ?? 28)
            _isOutlier = State(initialValue: existing.isOutlier)
        }
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("经期时间记录").font(.system(size: 13, weight: .semibold))) {
                    DatePicker("月经开始日期", selection: $startDate, displayedComponents: .date)

                    Stepper("经期持续天数: \(periodLength) 天", value: $periodLength, in: 1...14)

                    Stepper("周期天数: \(cycleLength) 天", value: $cycleLength, in: 15...60)
                }

                Section(
                    header: Text("特殊周期调节").font(.system(size: 13, weight: .semibold)),
                    footer: Text("开启后，系统在智能预测时会自动调优此特殊周期的影响，让预测更贴合您的常态。").font(.system(size: 12)).foregroundColor(.secondary)
                ) {
                    Toggle("本周期身体不适 / 服药 / 时差", isOn: $isOutlier)
                }
            }
            .navigationTitle(editingCycle == nil ? "添加历史经期" : "编辑历史经期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let cal = Calendar.current
                        let endDate = cal.date(byAdding: .day, value: cycleLength - 1, to: startDate)

                        let newCycle = Cycle(
                            id: editingCycle?.id ?? UUID(),
                            startDate: startDate,
                            endDate: endDate,
                            cycleLength: cycleLength,
                            periodLength: periodLength,
                            isOutlier: isOutlier
                        )
                        onSave(newCycle)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.periodRuby)
                }
            }
        }
    }
}
