import SwiftUI

/// 快捷打卡 Sheet 视图
public struct DailyLogSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let dateString: String
    let existingLog: DailyLog?
    let onSave: (DailyLog) -> Void

    @State private var flowLevel: Int? = nil
    @State private var bbtString: String = ""
    @State private var lhTestResult: String? = nil
    @State private var cervicalMucus: String? = nil
    @State private var selectedSymptoms: Set<String> = []
    @State private var selectedMoods: Set<String> = []
    @State private var notes: String = ""

    // 可选标签列表
    private let availableSymptoms = ["痛经", "腰酸", "痘痘", "头痛", "乳房胀痛", "腹胀感", "水肿", "失眠", "疲惫"]
    private let availableMoods = ["平静", "开心", "焦虑", "易怒", "低落", "敏感", "充沛"]

    public init(
        dateString: String,
        existingLog: DailyLog? = nil,
        onSave: @escaping (DailyLog) -> Void
    ) {
        self.dateString = dateString
        self.existingLog = existingLog
        self.onSave = onSave

        _flowLevel = State(initialValue: existingLog?.flowLevel)
        _bbtString = State(initialValue: existingLog?.bbt != nil ? String(format: "%.2f", existingLog!.bbt!) : "")
        _lhTestResult = State(initialValue: existingLog?.lhTestResult)
        _cervicalMucus = State(initialValue: existingLog?.cervicalMucus)
        _selectedSymptoms = State(initialValue: Set(existingLog?.symptoms ?? []))
        _selectedMoods = State(initialValue: Set(existingLog?.moods ?? []))
        _notes = State(initialValue: existingLog?.notes ?? "")
    }

    public var body: some View {
        NavigationView {
            Form {
                // 日期展示 Header
                Section {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Theme.periodRuby)
                        Text("打卡日期：\(dateString)")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }

                // 1. 经期流量
                Section(header: Text("经期流量").font(.system(size: 13, weight: .semibold))) {
                    HStack(spacing: 12) {
                        FlowButton(level: 1, title: "微量", currentLevel: $flowLevel)
                        FlowButton(level: 2, title: "少量", currentLevel: $flowLevel)
                        FlowButton(level: 3, title: "中等", currentLevel: $flowLevel)
                        FlowButton(level: 4, title: "偏多", currentLevel: $flowLevel)
                        FlowButton(level: 5, title: "特多", currentLevel: $flowLevel)
                    }
                    .padding(.vertical, 4)
                }

                // 2. 基础体温 (BBT) & 测纸
                Section(header: Text("体温与排卵检测").font(.system(size: 13, weight: .semibold))) {
                    HStack {
                        Text("基础体温 (BBT)")
                        Spacer()
                        TextField("例如 36.65", text: $bbtString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("℃")
                            .foregroundColor(.secondary)
                    }

                    Picker("排卵试纸结果", selection: $lhTestResult) {
                        Text("未测试").tag(String?.none)
                        Text("阴性 (-)").tag(String?.some("negative"))
                        Text("阳性 (+)").tag(String?.some("positive"))
                        Text("强阳/峰值 (Peak)").tag(String?.some("peak"))
                    }

                    Picker("宫颈黏液", selection: $cervicalMucus) {
                        Text("未观察").tag(String?.none)
                        Text("干燥 (Dry)").tag(String?.some("dry"))
                        Text("粘稠 (Sticky)").tag(String?.some("sticky"))
                        Text("乳液状 (Creamy)").tag(String?.some("creamy"))
                        Text("蛋清状 (Egg White)").tag(String?.some("eggWhite"))
                    }
                }

                // 3. 身体症状
                Section(header: Text("身体症状标签").font(.system(size: 13, weight: .semibold))) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableSymptoms, id: \.self) { symptom in
                                TagChip(
                                    title: symptom,
                                    isSelected: selectedSymptoms.contains(symptom),
                                    activeColor: Theme.periodRuby
                                ) {
                                    if selectedSymptoms.contains(symptom) {
                                        selectedSymptoms.remove(symptom)
                                    } else {
                                        selectedSymptoms.insert(symptom)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 4. 情绪心理
                Section(header: Text("情绪状态").font(.system(size: 13, weight: .semibold))) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableMoods, id: \.self) { mood in
                                TagChip(
                                    title: mood,
                                    isSelected: selectedMoods.contains(mood),
                                    activeColor: Theme.lutealPurple
                                ) {
                                    if selectedMoods.contains(mood) {
                                        selectedMoods.remove(mood)
                                    } else {
                                        selectedMoods.insert(mood)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 5. 备注随手记
                Section(header: Text("备注随手记").font(.system(size: 13, weight: .semibold))) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("记录健康日志")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let bbtVal = Double(bbtString)
                        let log = DailyLog(
                            date: dateString,
                            flowLevel: flowLevel,
                            bbt: bbtVal,
                            lhTestResult: lhTestResult,
                            cervicalMucus: cervicalMucus,
                            symptoms: Array(selectedSymptoms),
                            moods: Array(selectedMoods),
                            notes: notes.isEmpty ? nil : notes
                        )
                        onSave(log)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.periodRuby)
                }
            }
        }
    }

    // 流量选择按钮
    private struct FlowButton: View {
        let level: Int
        let title: String
        @Binding var currentLevel: Int?

        var isSelected: Bool { currentLevel == level }

        var body: some View {
            Button(action: {
                currentLevel = (currentLevel == level) ? nil : level
            }) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(isSelected ? Theme.periodRuby : Color.gray.opacity(0.15))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("\(level)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isSelected ? .white : .secondary)
                        )
                    Text(title)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? Theme.periodRuby : .secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity)
        }
    }

    // 标签 Chip 组件
    private struct TagChip: View {
        let title: String
        let isSelected: Bool
        let activeColor: Color
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isSelected ? activeColor.opacity(0.15) : Color.gray.opacity(0.1))
                    .foregroundColor(isSelected ? activeColor : .primary)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? activeColor : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

