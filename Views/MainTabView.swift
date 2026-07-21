import SwiftUI

/// 应用主界面 (思雨经期助手 — 优雅双排 TabBar 导航)
public struct MainTabView: View {
    @State private var userProfile = UserProfile()
    @State private var historyCycles: [Cycle] = []
    @State private var dailyLogs: [String: DailyLog] = [:]

    @State private var selectedDate: Date = Date()
    @State private var isLogSheetPresented: Bool = false
    @State private var isAddHistorySheetPresented: Bool = false
    @State private var editingCycle: Cycle? = nil
    @State private var activeTab: Int = 0

    // 计算获得的智能自适应预测结果
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
            // TAB 1: 首页仪表盘与关怀
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        // 1. 周期状态环形轮盘与每日关怀
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

                        // 2. 极简月历视图卡片 (纯 SF Symbols 区分各阶段)
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
                .navigationTitle("思雨经期助手")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("首页关怀", systemImage: "heart.circle.fill")
            }
            .tag(0)

            // TAB 2: 趋势与历史记录
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        // 自适应数据概览卡片
                        StatsOverviewCard(
                            avgCycleLength: predictionResult.predictedCycleLength,
                            avgPeriodLength: predictionResult.predictedPeriodLength,
                            totalCyclesCount: historyCycles.count
                        )

                        // 历史周期记录列表 (包含添加/修改/删除)
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
                .navigationTitle("健康历史与轨迹")
            }
            .tabItem {
                Label("健康历史", systemImage: "chart.bar.fill")
            }
            .tag(1)

            // TAB 3: 提醒与隐私设置
            NavigationView {
                Form {
                    Section(header: Text("智能提醒关怀")) {
                        Toggle("经期来潮提醒 (提前 2 天)", isOn: Binding(
                            get: { userProfile.isReminderEnabled },
                            set: { newValue in
                                userProfile.isReminderEnabled = newValue
                                saveUserProfile()
                                if newValue {
                                    NotificationManager.requestAuthorization { granted in
                                        if granted {
                                            NotificationManager.schedulePeriodReminder(
                                                predictedStartDate: predictionResult.nextPeriodStartDate,
                                                isEnabled: true
                                            )
                                        }
                                    }
                                } else {
                                    NotificationManager.schedulePeriodReminder(
                                        predictedStartDate: predictionResult.nextPeriodStartDate,
                                        isEnabled: false
                                    )
                                }
                            }
                        ))

                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(Theme.periodRuby)
                            Text("系统自动在预测来潮前 2 天温馨提醒您准备用品")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }

                    Section(header: Text("端侧隐私安全")) {
                        Toggle("开启应用锁 (Face ID / 密码)", isOn: Binding(
                            get: { userProfile.isPrivacyLockEnabled },
                            set: { userProfile.isPrivacyLockEnabled = $0; saveUserProfile() }
                        ))
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Theme.fertileTeal)
                            Text("所有健康日志均加密存放在 iPhone 本地沙盒，无云端上传")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }

                    Section(header: Text("关于思雨")) {
                        HStack {
                            Text("软件版本")
                            Spacer()
                            Text("v1.0.0 (自适应智能引擎)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("设置与关怀")
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
        
        // 自动调度下一次来潮提醒
        if userProfile.isReminderEnabled {
            NotificationManager.schedulePeriodReminder(
                predictedStartDate: predictionResult.nextPeriodStartDate,
                isEnabled: true
            )
        }
    }

    private func saveCycles() {
        self.historyCycles.sort(by: { $0.startDate < $1.startDate })
        CycleDataStore.saveCycles(self.historyCycles)
        
        if userProfile.isReminderEnabled {
            NotificationManager.schedulePeriodReminder(
                predictedStartDate: predictionResult.nextPeriodStartDate,
                isEnabled: true
            )
        }
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
        let pLen = predictionResult.predictedPeriodLength
        let cLen = predictionResult.predictedCycleLength
        
        if cur <= pLen {
            return "月经期"
        } else if cur >= (cLen - 19) && cur <= (cLen - 13) {
            if cur == (cLen - 14) {
                return "排卵日"
            } else {
                return "排酸期 / 易孕期"
            }
        } else if cur > (cLen - 13) {
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

// MARK: - 选中日期摘要明细卡片 (纯 SF Symbols)
struct SelectedDateSummaryCard: View {
    let dateString: String
    let dailyLog: DailyLog?
    let onEditTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(Theme.periodRuby)
                    Text("\(dateString) 日志明细")
                        .font(.system(size: 15, weight: .bold))
                }
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
                        Label("流量 Level \(flow)", systemImage: "drop.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.periodRuby)
                    }

                    if let water = log.waterIntake {
                        Label("\(water) ml", systemImage: "drop.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.fertileTeal)
                    }

                    if let weight = log.weight {
                        Label(String(format: "%.1f kg", weight), systemImage: "scalemass.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.lutealPurple)
                    }
                }

                if !log.symptoms.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("症状：\(log.symptoms.joined(separator: " / "))")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                if !log.moods.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "face.smiling.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("情绪：\(log.moods.joined(separator: " / "))")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                if let notes = log.notes, !notes.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("随记：\(notes)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("当日暂无详细打卡，点击右上角记录身体状态。")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }
}

// MARK: - 统计分析概览卡片 (自适应推算结果)
struct StatsOverviewCard: View {
    let avgCycleLength: Int
    let avgPeriodLength: Int
    let totalCyclesCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(Theme.periodRuby)
                Text("自适应算法推算概览")
                    .font(.system(size: 16, weight: .bold))
            }

            HStack {
                StatItem(title: "平均周期天数", value: "\(avgCycleLength) 天")
                Divider()
                StatItem(title: "平均经期天数", value: "\(avgPeriodLength) 天")
                Divider()
                StatItem(title: "历史记录", value: "\(totalCyclesCount) 次")
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
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.periodRuby)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 历史周期列表
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
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(Theme.periodRuby)
                    Text("历史周期记录")
                        .font(.system(size: 16, weight: .bold))
                }
                Spacer()
                Button(action: onAddTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("添加经期")
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
                                HStack(spacing: 4) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 10))
                                    Text("已自动平滑预测算法权重")
                                        .font(.system(size: 11))
                                }
                                .foregroundColor(.secondary)
                            } else {
                                Text("经期 \(cycle.periodLength ?? 5) 天 / 周期 \(cycle.cycleLength ?? 28) 天")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        HStack(spacing: 14) {
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
