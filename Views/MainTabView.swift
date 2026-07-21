import SwiftUI

/// 应用主界面 (TabBar 导航)
public struct MainTabView: View {
    @State private var userProfile = UserProfile()
    @State private var historyCycles: [Cycle] = []
    @State private var dailyLogs: [String: DailyLog] = [:]
    
    @State private var selectedDate: Date = Date()
    @State private var isLogSheetPresented: Bool = false
    @State private var activeTab: Int = 0

    // 计算得到的预测结果
    private var predictionResult: PredictionResult {
        PredictionEngine.predictNextCycle(historyCycles: historyCycles, userProfile: userProfile)
    }

    private var selectedDateString: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: selectedDate)
    }

    public init() {}

    public var body: some View {
        TabView(selection: $activeTab) {
            // TAB 1: 首页仪表盘
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        // 1. 周期状态环形轮盘
                        CycleWheelView(
                            currentDayInCycle: calculateCurrentDayInCycle(),
                            totalPredictedCycleLength: predictionResult.predictedCycleLength,
                            phaseName: calculatePhaseName(),
                            countdownDays: calculateCountdownDays(),
                            predictionResult: predictionResult,
                            onQuickLogTap: {
                                isLogSheetPresented = true
                            }
                        )

                        // 2. 极简月历视图卡片
                        CalendarCardView(
                            selectedDate: $selectedDate,
                            predictionResult: predictionResult,
                            historyCycles: historyCycles,
                            dailyLogs: dailyLogs
                        )

                        // 3. 选中日期的明细打卡展示卡片
                        SelectedDateSummaryCard(
                            dateString: selectedDateString,
                            dailyLog: dailyLogs[selectedDateString],
                            onEditTap: { isLogSheetPresented = true }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
                .background(Theme.backgroundGradient.ignoresSafeArea())
                .navigationTitle("智能经期预测")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("仪表盘", systemImage: "heart.circle.fill")
            }
            .tag(0)

            // TAB 2: 趋势与规律分析
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        // 周期统计数据卡片
                        StatsOverviewCard(
                            avgCycleLength: predictionResult.predictedCycleLength,
                            avgPeriodLength: userProfile.defaultPeriodLength,
                            totalCyclesCount: historyCycles.count,
                            outliersCount: predictionResult.outliersCount
                        )

                        // 历史周期列表
                        HistoryCyclesListCard(historyCycles: historyCycles)
                    }
                    .padding(16)
                }
                .background(Theme.backgroundGradient.ignoresSafeArea())
                .navigationTitle("周期统计")
            }
            .tabItem {
                Label("数据统计", systemImage: "chart.bar.fill")
            }
            .tag(1)

            // TAB 3: 设置与隐私
            NavigationView {
                Form {
                    Section(header: Text("生理基线参数")) {
                        HStack {
                            Text("默认周期天数")
                            Spacer()
                            Stepper("\(userProfile.defaultCycleLength) 天", value: $userProfile.defaultCycleLength, in: 20...45)
                        }
                        HStack {
                            Text("默认经期天数")
                            Spacer()
                            Stepper("\(userProfile.defaultPeriodLength) 天", value: $userProfile.defaultPeriodLength, in: 2...10)
                        }
                        HStack {
                            Text("默认黄体期")
                            Spacer()
                            Stepper("\(userProfile.lutealPhaseLength) 天", value: $userProfile.lutealPhaseLength, in: 10...16)
                        }
                    }

                    Section(header: Text("隐私与安全")) {
                        Toggle("开启应用锁 (Face ID / 密码)", isOn: $userProfile.isPrivacyLockEnabled)
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Theme.fertileTeal)
                            Text("所有数据均保存在本地，无云端同步")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("个人设置")
            }
            .tabItem {
                Label("设置", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .accentColor(Theme.periodRuby)
        .onAppear {
            loadInitialMockDataIfNeeded()
        }
        .sheet(isPresented: $isLogSheetPresented) {
            DailyLogSheetView(
                dateString: selectedDateString,
                existingLog: dailyLogs[selectedDateString]
            ) { updatedLog in
                dailyLogs[updatedLog.date] = updatedLog
                
                // 如果勾选了经期流量，自动更新/追加经期开始记录
                if (updatedLog.flowLevel ?? 0) > 0 {
                    checkAndUpdateCycleRecord(for: updatedLog.date)
                }
            }
        }
    }

    // MARK: - 状态辅助计算
    private func calculateCurrentDayInCycle() -> Int {
        guard let lastCycle = historyCycles.sorted(by: { $0.startDate < $1.startDate }).last else {
            return 1
        }
        let days = Calendar.current.dateComponents([.day], from: lastCycle.startDate, to: Date()).day ?? 0
        return max(1, days + 1)
    }

    private func calculatePhaseName() -> String {
        let cur = calculateCurrentDayInCycle()
        if cur <= userProfile.defaultPeriodLength {
            return "月经期"
        } else if cur >= (predictionResult.predictedCycleLength - 19) && cur <= (predictionResult.predictedCycleLength - 13) {
            return "排卵期 / 易孕期"
        } else if cur > (predictionResult.predictedCycleLength - 13) {
            return "黄体期"
        } else {
            return "滤泡期 / 安全期"
        }
    }

    private func calculateCountdownDays() -> Int {
        let cur = calculateCurrentDayInCycle()
        return max(0, predictionResult.predictedCycleLength - cur)
    }

    private func checkAndUpdateCycleRecord(for dateStr: String) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        guard let logDate = df.date(from: dateStr) else { return }

        // 如果与上个周期相隔超过 15 天，认为是新周期开始
        if let lastCycle = historyCycles.sorted(by: { $0.startDate < $1.startDate }).last {
            let diff = Calendar.current.dateComponents([.day], from: lastCycle.startDate, to: logDate).day ?? 0
            if diff >= 15 {
                var updatedLast = lastCycle
                updatedLast.endDate = Calendar.current.date(byAdding: .day, value: -1, to: logDate)
                updatedLast.cycleLength = diff
                
                let newCycle = Cycle(startDate: logDate, periodLength: 5)
                historyCycles.append(newCycle)
            }
        } else {
            let firstCycle = Cycle(startDate: logDate, periodLength: 5)
            historyCycles.append(firstCycle)
        }
    }

    private func loadInitialMockDataIfNeeded() {
        if historyCycles.isEmpty {
            let cal = Calendar.current
            let now = Date()
            
            // 生成2个最近的示例历史周期数据
            let c1Start = cal.date(byAdding: .day, value: -56, to: now)!
            let c1End = cal.date(byAdding: .day, value: -29, to: now)!
            let c1 = Cycle(startDate: c1Start, endDate: c1End, cycleLength: 28, periodLength: 5)

            let c2Start = cal.date(byAdding: .day, value: -28, to: now)!
            let c2End = cal.date(byAdding: .day, value: -1, to: now)!
            let c2 = Cycle(startDate: c2Start, endDate: c2End, cycleLength: 28, periodLength: 5)

            historyCycles = [c1, c2]
        }
    }
}

// MARK: - 选中日期摘要明细卡片
struct SelectedDateSummaryCard: View {
    let dateString: String
    let dailyLog: DailyLog?
    let onEditTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("📅 \(dateString) 日志明细")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button(action: onEditTap) {
                    Text(dailyLog == nil ? "添加打卡" : "编辑日志")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.periodRuby)
                }
            }

            if let log = dailyLog {
                HStack(spacing: 16) {
                    if let flow = log.flowLevel {
                        Label("流量: Level \(flow)", systemImage: "drop.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.periodRuby)
                    }

                    if let bbt = log.bbt {
                        Label(String(format: "%.2f℃", bbt), systemImage: "thermometer.medium")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.fertileTeal)
                    }
                }

                if !log.symptoms.isEmpty {
                    Text("症状：\(log.symptoms.joined(separator: " / "))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                if !log.moods.isEmpty {
                    Text("情绪：\(log.moods.joined(separator: " / "))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                if let notes = log.notes, !notes.isEmpty {
                    Text("备注：\(notes)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("当日暂无详细打卡，点击右上角进行添加。")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }
}

// MARK: - 统计分析卡片
struct StatsOverviewCard: View {
    let avgCycleLength: Int
    let avgPeriodLength: Int
    let totalCyclesCount: Int
    let outliersCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("规律性概览")
                .font(.system(size: 16, weight: .bold))

            HStack {
                StatItem(title: "平均周期", value: "\(avgCycleLength) 天")
                Divider()
                StatItem(title: "平均经期", value: "\(avgPeriodLength) 天")
                Divider()
                StatItem(title: "有效记录", value: "\(totalCyclesCount) 次")
            }
        }
        .cardStyle()
    }

    private struct StatItem: View {
        let title: String
        let value: String

        var body: some View {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.periodRuby)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct HistoryCyclesListCard: View {
    let historyCycles: [Cycle]

    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史周期记录")
                .font(.system(size: 16, weight: .bold))

            ForEach(historyCycles.sorted(by: { $0.startDate > $1.startDate })) { cycle in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(df.string(from: cycle.startDate))
                            .font(.system(size: 14, weight: .semibold))
                        if cycle.isOutlier {
                            Text("异常离群周期 (\(cycle.outlierReason ?? "未标注"))")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        }
                    }
                    Spacer()
                    Text("\(cycle.cycleLength ?? 28) 天")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.periodRuby)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .cardStyle()
    }
}
