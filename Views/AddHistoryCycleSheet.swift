import SwiftUI

/// 手动添加/编辑历史经期记录 Sheet
public struct AddHistoryCycleSheet: View {
    @Environment(\.dismiss) private var dismiss

    let editingCycle: Cycle?
    let onSave: (Cycle) -> Void

    @State private var startDate: Date = Date()
    @State private var periodLength: Int = 5
    @State private var cycleLength: Int = 28
    @State private var isOutlier: Bool = false
    @State private var outlierReason: String = ""

    public init(editingCycle: Cycle? = nil, onSave: @escaping (Cycle) -> Void) {
        self.editingCycle = editingCycle
        self.onSave = onSave

        if let existing = editingCycle {
            _startDate = State(initialValue: existing.startDate)
            _periodLength = State(initialValue: existing.periodLength ?? 5)
            _cycleLength = State(initialValue: existing.cycleLength ?? 28)
            _isOutlier = State(initialValue: existing.isOutlier)
            _outlierReason = State(initialValue: existing.outlierReason ?? "")
        }
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("经期基础数据").font(.system(size: 13, weight: .semibold))) {
                    DatePicker("月经开始日期", selection: $startDate, displayedComponents: .date)

                    Stepper("经期持续天数: \(periodLength) 天", value: $periodLength, in: 1...14)

                    Stepper("本周期总天数: \(cycleLength) 天", value: $cycleLength, in: 15...60)
                        .help("从本次月经第一天，到下次月经前一天的总天数")
                }

                Section(
                    header: Text("异常/离群记录说明").font(.system(size: 13, weight: .semibold)),
                    footer: Text("标记为离群周期后，算法在计算平均值与 EMA 时会自动忽略此周期的干扰，使预测更准确。").font(.system(size: 12)).foregroundColor(.secondary)
                ) {
                    Toggle("标记为异常离群周期", isOn: $isOutlier)

                    if isOutlier {
                        TextField("离群原因（如：服药、生病、长途时差等）", text: $outlierReason)
                    }
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
                            isOutlier: isOutlier,
                            outlierReason: isOutlier ? (outlierReason.isEmpty ? "手动标注异常" : outlierReason) : nil
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
