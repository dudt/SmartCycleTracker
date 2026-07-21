import SwiftUI

/// 应用主界面 (TabBar 导航)
public struct MainTabView: View {
    @State private var userProfile = UserProfile()
    @State private var historyCycles: [Cycle] = []
    @State private var dailyLogs: [String: DailyLog] = [:]

    @State private var selectedDate: Date = Date()
    @State private var isLogSheetPresented: Bool = false
    @State private var isAddHistorySheetPresented: Bool = false
    @State private var editingCycle: Cycle? = nil
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

            // TAB 2: 趋势与历史记录
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

                        // 历史周期记录列表 (包含添加/删除功能)
                        HistoryCyclesListCard(
                            historyCycles: historyCycles,
                            onAddTap: {
                                editingCycle = nil
                                isAddHistorySheetPresented = true
                            },
                            onDelete: { cycle in
                                deleteCycle(cycle)
                            },
                            onEdit: { cycle in
                                editingCycle = cycle
                                isAddHistorySheetPresented = true
                            }
                        )
                    }
                    .padding(16)
                }
                .background(Theme.backgroundGradient.ignoresSafeArea())
                .navigationTitle("周期统计与历史")
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
                                .onChange(of: userProfile.defaultCycleLength) { _ in saveUserProfile() }
                        }
                        HStack {
                            Text("默认经期天数")
                            Spacer()
                            Stepper("\(userProfile.defaultPeriodLength) 天", value: $userProfile.defaultPeriodLength, in: 2...10)
                                .onChange(of: userProfile.defaultPeriodLength) { _ in saveUserProfile() }
                        }
                        HStack {
                            Text("默认黄体期")
                            Spacer()
                            Stepper("\(userProfile.lutealPhaseLength) 天", value: $userProfile.lutealPhaseLength, in: 10...16)
                                .onChange(of: userProfile.lutealPhaseLength) { _ in saveUserProfile() }
                        }
                    }

                    Section(header: Text("隐私与安全")) {
                        Toggle("开启应用锁 (Face ID / 密码)", isOn: $userProfile.isPrivacyLockEnabled)
                            .onChange(of: userProfile.isPrivacyLockEnabled) { _ in saveUserProfile() }
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Theme.fertileTeal)
                            Text("所有数据均保存在本地沙盒，无任何云端同步")
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
            loadLocalData()
        }
        .sheet(isPresented: $isLogSheetPresented) {
            DailyLogSheetView(
                dateString: selectedDateString,
                existingLog: dailyLogs[selectedDateString]
            ) { updatedLog in
                dailyLogs[updatedLog.date] = updatedLog
                CycleDataStore.saveDailyLogs(dailyLogs)

                if (updatedLog.flowLevel ?? 0) > 0 {
                    checkAndUpdateCycleRecord(for: updatedLog.date)
                }
            }
        }
        .sheet(isPresented: $isAddHistorySheetPresented) {
            AddHistoryCycleSheet(editingCycle: editingCycle) { savedCycle in
                if let index = historyCycles.firstIndex(where: { $0.id == savedCycle.id }) {
                    historyCycles[index] = savedCycle
                } else {
                    historyCycles.append(savedCycle)
                }
                saveCycles()
            }
        }
    }

    // MARK: - 本地持久化与辅助计算
    private func loadLocalData() {
        let loadedCycles = CycleDataStore.loadCycles()
        let loadedLogs = CycleDataStore.loadDailyLogs()
        let loadedProfile = CycleDataStore.loadProfile()

        self.userProfile = loadedProfile
        self.dailyLogs = loadedLogs

        if loadedCycles.isEmpty {
            // 提供演示初始数据
            let cal = Calendar.current
            let now = Date()
            let c1Start = cal.date(byAdding: .day, value: -56, to: now)!
            let c1End = cal.date(byAdding: .day, value: -29, to: now)!
            let c1 = Cycle(startDate: c1Start, endDate: c1End, cycleLength: 28, periodLength: 5)

            let c2Start = cal.date(byAdding: .day, value: -28, to: now)!
            let c2End = cal.date(byAdding: .day, value: -1, to: now)!
            let c2 = Cycle(startDate: c2Start, endDate: c2End, cycleLength: 28, periodLength: 5)

            self.historyCycles = [c1, c2]
            CycleDataStore.saveCycles(self.historyCycles)
        } else {
            self.historyCycles = loadedCycles
        }
    }

    private func saveCycles() {
        self.historyCycles.sort(by: { $0.startDate < $1.startDate })
        CycleDataStore.saveCycles(self.historyCycles)
    }

    private func saveUserProfile() {
        CycleDataStore.saveProfile(self.userProfile)
    }

    private func deleteCycle(_ cycle: Cycle) {
        historyCycles.removeAll(where: { $0.id == cycle.id })
        saveCycles()
    }

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

        if let lastCycle = historyCycles.sorted(by: { $0.startDate < $1.startDate }).last {
            let diff = Calendar.current.dateComponents([.day], from: lastCycle.startDate, to: logDate).day ?? 0
            if diff >= 15 {
                var updatedLast = lastCycle
                updatedLast.endDate = Calendar.current.date(byAdding: .day, value: -1, to: logDate)
                updatedLast.cycleLength = diff
                if let idx = historyCycles.firstIndex(where: { $0.id == lastCycle.id }) {
                    historyCycles[idx] = updatedLast
                }

                let newCycle = Cycle(startDate: logDate, periodLength: userProfile.defaultPeriodLength)
                historyCycles.append(newCycle)
                saveCycles()
            }
        } else {
            let firstCycle = Cycle(startDate: logDate, periodLength: userProfile.defaultPeriodLength)
            historyCycles.append(firstCycle)
            saveCycles()
        }
    }
}

// MARK: - 历史周期数据展示列表 (带添加与删除按钮)
struct HistoryCyclesListCard: View {
    let historyCycles: [Cycle]
    let onAddTap: () -> Void
    let onDelete: (Cycle) -> Void
    let onEdit: (Cycle) -> Void

    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("历史周期记录")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button(action: onAddTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("添加历史经期")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.periodRuby)
                }
            }

            if historyCycles.isEmpty {
                Text("暂无历史记录，点击右上角添加历史经期。")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(historyCycles.sorted(by: { $0.startDate > $1.startDate })) { cycle in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(df.string(from: cycle.startDate))
                                .font(.system(size: 14, weight: .semibold))
                            
                            if cycle.isOutlier {
                                Text("⚠️ 离群周期 (\(cycle.outlierReason ?? "手动标注"))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                            } else {
                                Text("经期: \(cycle.periodLength ?? 5)天 / 周期: \(cycle.cycleLength ?? 28)天")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // 编辑与删除操作按钮
                        HStack(spacing: 12) {
                            Button(action: { onEdit(cycle) }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }

                            Button(action: { onDelete(cycle) }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }
        .cardStyle()
    }
}
