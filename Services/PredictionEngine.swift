import Foundation

/// 预测结果封装结构
public struct PredictionResult: Equatable {
    public let predictedCycleLength: Int
    public let predictedPeriodLength: Int
    public let nextPeriodStartDate: Date
    public let nextPeriodEndDate: Date
    public let ovulationDate: Date
    public let fertileWindowStart: Date
    public let fertileWindowEnd: Date
    public let confidenceMarginDays: Double
    public let confidenceRangeStart: Date
    public let confidenceRangeEnd: Date
    public let validCyclesCount: Int
}

/// 智能自适应经期预测引擎（无感调优，越用越准）
public struct PredictionEngine {
    
    public static func predictNextCycle(
        historyCycles: [Cycle],
        userProfile: UserProfile,
        lastPeriodStartDate: Date? = nil
    ) -> PredictionResult {
        let calendar = Calendar.current
        let completedCycles = historyCycles.filter { $0.cycleLength != nil && ($0.cycleLength ?? 0) > 0 }
        
        var validCycleLengths: [Double] = []
        var validPeriodLengths: [Double] = []
        
        if completedCycles.count >= 3 {
            // 步骤 1: 自动离群值校验 (|X_i - μ| > 1.5 * σ)
            let lengths = completedCycles.compactMap { Double($0.cycleLength!) }
            let mean = lengths.reduce(0, +) / Double(lengths.count)
            let variance = lengths.map { pow($0 - mean, 2) }.reduce(0, +) / Double(lengths.count)
            let stdDev = sqrt(variance)
            
            for cycle in completedCycles {
                let length = Double(cycle.cycleLength!)
                let isDeviant = abs(length - mean) > (1.5 * stdDev)
                if !cycle.isOutlier && !isDeviant {
                    validCycleLengths.append(length)
                    if let pLen = cycle.periodLength {
                        validPeriodLengths.append(Double(pLen))
                    }
                }
            }
        } else {
            for cycle in completedCycles {
                if !cycle.isOutlier, let len = cycle.cycleLength {
                    validCycleLengths.append(Double(len))
                    if let pLen = cycle.periodLength {
                        validPeriodLengths.append(Double(pLen))
                    }
                }
            }
        }
        
        // 步骤 2: 指数加权移动平均 (EMA) 智能计算近期趋势 (α = 0.5)
        let alpha: Double = 0.5
        let calculatedCycleLength: Double
        if validCycleLengths.isEmpty {
            calculatedCycleLength = Double(userProfile.defaultCycleLength)
        } else {
            var ema = validCycleLengths[0]
            for i in 1..<validCycleLengths.count {
                ema = alpha * validCycleLengths[i] + (1.0 - alpha) * ema
            }
            calculatedCycleLength = ema
        }
        
        let calculatedPeriodLength: Double
        if validPeriodLengths.isEmpty {
            calculatedPeriodLength = Double(userProfile.defaultPeriodLength)
        } else {
            calculatedPeriodLength = validPeriodLengths.reduce(0, +) / Double(validPeriodLengths.count)
        }
        
        let finalCycleLengthInt = Int(max(21, min(45, round(calculatedCycleLength))))
        let finalPeriodLengthInt = Int(max(2, min(10, round(calculatedPeriodLength))))
        
        // 步骤 3: 日期计算
        let baseStartDate: Date
        if let explicitLastDate = lastPeriodStartDate {
            baseStartDate = explicitLastDate
        } else if let lastCycle = historyCycles.sorted(by: { $0.startDate < $1.startDate }).last {
            baseStartDate = lastCycle.startDate
        } else {
            baseStartDate = Date()
        }
        
        let predictedStartDate = calendar.date(byAdding: .day, value: finalCycleLengthInt, to: baseStartDate)!
        let predictedEndDate = calendar.date(byAdding: .day, value: finalPeriodLengthInt - 1, to: predictedStartDate) ?? predictedStartDate
        
        let lutealDays = max(10, min(16, userProfile.lutealPhaseLength))
        let ovulationDate = calendar.date(byAdding: .day, value: -lutealDays, to: predictedStartDate) ?? predictedStartDate
        let fertileStart = calendar.date(byAdding: .day, value: -5, to: ovulationDate) ?? ovulationDate
        let fertileEnd = calendar.date(byAdding: .day, value: 1, to: ovulationDate) ?? ovulationDate
        
        // 步骤 4: 动态置信区间
        let stdDev: Double
        if validCycleLengths.count >= 2 {
            let mean = validCycleLengths.reduce(0, +) / Double(validCycleLengths.count)
            let sumSq = validCycleLengths.map { pow($0 - mean, 2) }.reduce(0, +)
            stdDev = sqrt(sumSq / Double(validCycleLengths.count))
        } else {
            stdDev = 1.5
        }
        
        let confidenceMarginDays = max(1.0, round(1.5 * stdDev * 10) / 10.0)
        let confidenceStart = calendar.date(byAdding: .day, value: Int(floor(-confidenceMarginDays)), to: predictedStartDate) ?? predictedStartDate
        let confidenceEnd = calendar.date(byAdding: .day, value: Int(ceil(confidenceMarginDays)), to: predictedStartDate) ?? predictedStartDate
        
        return PredictionResult(
            predictedCycleLength: finalCycleLengthInt,
            predictedPeriodLength: finalPeriodLengthInt,
            nextPeriodStartDate: predictedStartDate,
            nextPeriodEndDate: predictedEndDate,
            ovulationDate: ovulationDate,
            fertileWindowStart: fertileStart,
            fertileWindowEnd: fertileEnd,
            confidenceMarginDays: confidenceMarginDays,
            confidenceRangeStart: confidenceStart,
            confidenceRangeEnd: confidenceEnd,
            validCyclesCount: validCycleLengths.count
        )
    }
}
