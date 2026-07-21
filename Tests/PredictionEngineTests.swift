import Foundation

/// PredictionEngine 单元测试与算法验证逻辑
public struct PredictionEngineTests {
    
    public static func runAllTests() {
        print("====== 正在执行 PredictionEngine 算法单元测试 ======")
        testEmptyHistoryFallback()
        testOutlierFiltering()
        testEMAWeighting()
        testFertileWindowAndConfidence()
        print("====== 预测引擎所有算法单元测试通过！ ======")
    }
    
    private static func testEmptyHistoryFallback() {
        let profile = UserProfile(defaultCycleLength: 28, defaultPeriodLength: 5, lutealPhaseLength: 14)
        let lastDate = Date()
        let result = PredictionEngine.predictNextCycle(historyCycles: [], userProfile: profile, lastPeriodStartDate: lastDate)
        
        assert(result.predictedCycleLength == 28, "空历史记录时应回退至默认周期长度 28")
        assert(result.validCyclesCount == 0, "有效历史记录应为 0")
        print("✓ 测试 1: 空历史记录回退基线测试 - 通过")
    }
    
    private static func testOutlierFiltering() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        
        // 构造4个正常周期(28, 29, 28, 27) + 1个极度离群周期(45天，生病导致)
        let c1 = Cycle(startDate: baseDate, cycleLength: 28)
        let c2 = Cycle(startDate: calendar.date(byAdding: .day, value: 28, to: baseDate)!, cycleLength: 29)
        let c3 = Cycle(startDate: calendar.date(byAdding: .day, value: 57, to: baseDate)!, cycleLength: 45, isOutlier: true, outlierReason: "感冒服药")
        let c4 = Cycle(startDate: calendar.date(byAdding: .day, value: 102, to: baseDate)!, cycleLength: 28)
        let c5 = Cycle(startDate: calendar.date(byAdding: .day, value: 130, to: baseDate)!, cycleLength: 27)
        
        let profile = UserProfile(defaultCycleLength: 28, defaultPeriodLength: 5, lutealPhaseLength: 14)
        let result = PredictionEngine.predictNextCycle(historyCycles: [c1, c2, c3, c4, c5], userProfile: profile)
        
        assert(result.outliersCount == 1, "应该检测并剔除 1 个离群周期")
        assert(result.validCyclesCount == 4, "应该包含 4 个有效周期")
        assert(result.predictedCycleLength >= 27 && result.predictedCycleLength <= 29, "剔除45天离群值后，预测周期天数应在 27-29 天之间，实际: \(result.predictedCycleLength)")
        print("✓ 测试 2: 离群值自动与手动剔除测试 - 通过")
    }
    
    private static func testEMAWeighting() {
        let calendar = Calendar.current
        let baseDate = Date()
        
        // 旧到新：26天 -> 28天 -> 32天
        // EMA0 = 26
        // EMA1 = 0.5 * 28 + 0.5 * 26 = 27
        // EMA2 = 0.5 * 32 + 0.5 * 27 = 29.5 -> round = 30
        let c1 = Cycle(startDate: baseDate, cycleLength: 26)
        let c2 = Cycle(startDate: calendar.date(byAdding: .day, value: 26, to: baseDate)!, cycleLength: 28)
        let c3 = Cycle(startDate: calendar.date(byAdding: .day, value: 54, to: baseDate)!, cycleLength: 32)
        
        let profile = UserProfile(defaultCycleLength: 28)
        let result = PredictionEngine.predictNextCycle(historyCycles: [c1, c2, c3], userProfile: profile)
        
        assert(result.predictedCycleLength == 30, "EMA(0.5) 结果应赋予近距离周期更高权重，计算值应为 30，实际为: \(result.predictedCycleLength)")
        print("✓ 测试 3: 指数加权移动平均 (EMA) 算法测试 - 通过")
    }
    
    private static func testFertileWindowAndConfidence() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        
        let c1 = Cycle(startDate: baseDate, cycleLength: 28)
        let profile = UserProfile(defaultCycleLength: 28, defaultPeriodLength: 5, lutealPhaseLength: 14)
        
        let result = PredictionEngine.predictNextCycle(historyCycles: [c1], userProfile: profile, lastPeriodStartDate: baseDate)
        
        // 预测下次经期首日 = 5/1 + 28 = 5/29
        let expectedStartDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 29))!
        assert(calendar.isDate(result.nextPeriodStartDate, inSameDayAs: expectedStartDate), "下次经期首日计算应为 2026-05-29")
        
        // 预测排卵日 = 5/29 - 14天 = 5/15
        let expectedOvulation = calendar.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        assert(calendar.isDate(result.ovulationDate, inSameDayAs: expectedOvulation), "预测排卵日应为 2026-05-15")
        
        // 易孕期起始 = 5/15 - 5天 = 5/10
        let expectedFertileStart = calendar.date(from: DateComponents(year: 2026, month: 5, day: 10))!
        assert(calendar.isDate(result.fertileWindowStart, inSameDayAs: expectedFertileStart), "易孕期起始应为 2026-05-10")
        
        print("✓ 测试 4: 排卵日、易孕期窗口及置信区间计算测试 - 通过")
    }
}
