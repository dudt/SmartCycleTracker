import Foundation

/// 预测结果封装结构
public struct PredictionResult: Equatable {
    /// 预测的周期长度（天数）
    public let predictedCycleLength: Int
    /// 预测下次月经来潮首日
    public let nextPeriodStartDate: Date
    /// 预测下次月经结束日期
    public let nextPeriodEndDate: Date
    /// 预测排卵日
    public let ovulationDate: Date
    /// 易孕期起始日期 (排卵日前 5 天)
    public let fertileWindowStart: Date
    /// 易孕期结束日期 (排卵日后 1 天)
    public let fertileWindowEnd: Date
    /// 动态置信区间上下浮动范围（天数，例如 ±1.5 天）
    public let confidenceMarginDays: Double
    /// 置信区间推荐起始时间
    public let confidenceRangeStart: Date
    /// 置信区间推荐结束时间
    public let confidenceRangeEnd: Date
    /// 参与计算的有效历史周期数
    public let validCyclesCount: Int
    /// 被剔除的异常离群周期数
    public let outliersCount: Int

    public init(
        predictedCycleLength: Int,
        nextPeriodStartDate: Date,
        nextPeriodEndDate: Date,
        ovulationDate: Date,
        fertileWindowStart: Date,
        fertileWindowEnd: Date,
        confidenceMarginDays: Double,
        confidenceRangeStart: Date,
        confidenceRangeEnd: Date,
        validCyclesCount: Int,
        outliersCount: Int
    ) {
        self.predictedCycleLength = predictedCycleLength
        self.nextPeriodStartDate = nextPeriodStartDate
        self.nextPeriodEndDate = nextPeriodEndDate
        self.ovulationDate = ovulationDate
        self.fertileWindowStart = fertileWindowStart
        self.fertileWindowEnd = fertileWindowEnd
        self.confidenceMarginDays = confidenceMarginDays
        self.confidenceRangeStart = confidenceRangeStart
        self.confidenceRangeEnd = confidenceRangeEnd
        self.validCyclesCount = validCyclesCount
        self.outliersCount = outliersCount
    }
}

/// 智能经期预测引擎
public struct PredictionEngine {
    
    /// 执行智能预测逻辑
    /// - Parameters:
    ///   - cycles: 历史周期列表 (推荐按按时间从旧到新升序排列)
    ///   - profile: 用户生理基线参数
    ///   - referenceLastStartDate: 上次月经开始日期（若无历史记录则可以传当前日期）
    /// - Returns: 预测结果结构体 `PredictionResult`
    public static func predictNextCycle(
        historyCycles: [Cycle],
        userProfile: UserProfile,
        lastPeriodStartDate: Date? = nil
    ) -> PredictionResult {
        let calendar = Calendar.current
        
        // 1. 过滤有效周期：提取已结束且包含有效 cycleLength 的记录
        let completedCycles = historyCycles.filter { $0.cycleLength != nil && ($0.cycleLength ?? 0) > 0 }
        
        // 标记离群周期与有效周期
        var validCycleLengths: [Double] = []
        var outliersCount = 0
        
        if completedCycles.count >= 3 {
            // 步骤 1.1：计算均值 μ 与标准差 σ
            let lengths = completedCycles.compactMap { Double($0.cycleLength!) }
            let mean = lengths.reduce(0, +) / Double(lengths.count)
            
            let variance = lengths.map { pow($0 - mean, 2) }.reduce(0, +) / Double(lengths.count)
            let stdDev = sqrt(variance)
            
            // 步骤 1.2：剔除 |X_i - μ| > 1.5 * σ 或 手动标记为 outlier 的数据
            for cycle in completedCycles {
                let length = Double(cycle.cycleLength!)
                let isDeviant = abs(length - mean) > (1.5 * stdDev)
                
                if cycle.isOutlier || isDeviant {
                    outliersCount += 1
                } else {
                    validCycleLengths.append(length)
                }
            }
        } else {
            // 如果历史有效样本少于3个，仅过滤手动标记为 outlier 的周期
            for cycle in completedCycles {
                if cycle.isOutlier {
                    outliersCount += 1
                } else if let len = cycle.cycleLength {
                    validCycleLengths.append(Double(len))
                }
            }
        }
        
        // 2. 指数加权移动平均 (EMA) 计算
        // 参数 α = 2 / (N + 1)，建议 N = 3，故 α = 0.5
        let n: Double = 3.0
        let alpha: Double = 2.0 / (n + 1.0)
        
        let calculatedLength: Double
        if validCycleLengths.isEmpty {
            // 兜底使用用户设置的默认周期长度
            calculatedLength = Double(userProfile.defaultCycleLength)
        } else {
            // 按从旧到新顺序计算 EMA
            var ema = validCycleLengths[0]
            for i in 1..<validCycleLengths.count {
                ema = alpha * validCycleLengths[i] + (1.0 - alpha) * ema
            }
            calculatedLength = ema
        }
        
        // 限制合理范围 [21天, 45天]
        let finalCycleLengthInt = Int(max(21, min(45, round(calculatedLength))))
        
        // 3. 确定上次月经起始时间基准
        let baseStartDate: Date
        if let explicitLastDate = lastPeriodStartDate {
            baseStartDate = explicitLastDate
        } else if let lastCycle = historyCycles.sorted(by: { $0.startDate < $1.startDate }).last {
            baseStartDate = lastCycle.startDate
        } else {
            baseStartDate = Date()
        }
        
        // 4. 关键日期计算
        // (1) 下次月经首日 = 上次首日 + 预测周期天数
        guard let predictedStartDate = calendar.date(byAdding: .day, value: finalCycleLengthInt, to: baseStartDate) else {
            fatalError("Date math error")
        }
        
        // (2) 下次月经结束日 = 下次首日 + (默认经期天数 - 1)
        let periodDuration = max(1, userProfile.defaultPeriodLength)
        let predictedEndDate = calendar.date(byAdding: .day, value: periodDuration - 1, to: predictedStartDate) ?? predictedStartDate
        
        // (3) 预测排卵日 = 下次月经首日 - 黄体期天数 (默认14天)
        let lutealDays = max(10, min(16, userProfile.lutealPhaseLength))
        let ovulationDate = calendar.date(byAdding: .day, value: -lutealDays, to: predictedStartDate) ?? predictedStartDate
        
        // (4) 易孕期窗口 = [排卵日 - 5天, 排卵日 + 1天]
        let fertileStart = calendar.date(byAdding: .day, value: -5, to: ovulationDate) ?? ovulationDate
        let fertileEnd = calendar.date(byAdding: .day, value: 1, to: ovulationDate) ?? ovulationDate
        
        // 5. 动态置信区间计算 (Dynamic Confidence Interval)
        let stdDev: Double
        if validCycleLengths.count >= 2 {
            let mean = validCycleLengths.reduce(0, +) / Double(validCycleLengths.count)
            let sumSq = validCycleLengths.map { pow($0 - mean, 2) }.reduce(0, +)
            stdDev = sqrt(sumSq / Double(validCycleLengths.count))
        } else {
            stdDev = 1.5 // 缺乏数据时的预设偏差
        }
        
        // 置信区间上下浮动天数 Margin = max(1.0, 1.5 * stdDev)
        let confidenceMarginDays = max(1.0, round(1.5 * stdDev * 10) / 10.0)
        
        let rangeStartDays = Int(floor(-confidenceMarginDays))
        let rangeEndDays = Int(ceil(confidenceMarginDays))
        
        let confidenceStart = calendar.date(byAdding: .day, value: rangeStartDays, to: predictedStartDate) ?? predictedStartDate
        let confidenceEnd = calendar.date(byAdding: .day, value: rangeEndDays, to: predictedStartDate) ?? predictedStartDate
        
        return PredictionResult(
            predictedCycleLength: finalCycleLengthInt,
            nextPeriodStartDate: predictedStartDate,
            nextPeriodEndDate: predictedEndDate,
            ovulationDate: ovulationDate,
            fertileWindowStart: fertileStart,
            fertileWindowEnd: fertileEnd,
            confidenceMarginDays: confidenceMarginDays,
            confidenceRangeStart: confidenceStart,
            confidenceRangeEnd: confidenceEnd,
            validCyclesCount: validCycleLengths.count,
            outliersCount: outliersCount
        )
    }
}
