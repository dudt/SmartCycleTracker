import Foundation

// MARK: - 1. 周期记录实体 (Cycle)
public struct Cycle: Codable, Identifiable, Equatable {
    public var id: UUID
    public var startDate: Date          // 周期开始日期 (月经第一天)
    public var endDate: Date?           // 周期结束日期 (下次月经前一天)
    public var cycleLength: Int?        // 本周期总天数
    public var periodLength: Int?       // 经期持续天数
    public var isOutlier: Bool          // 是否被标记为离群/异常周期（如生病、服药、长途旅行等）
    public var outlierReason: String?   // 离群原因
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        cycleLength: Int? = nil,
        periodLength: Int? = nil,
        isOutlier: Bool = false,
        outlierReason: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.cycleLength = cycleLength
        self.periodLength = periodLength
        self.isOutlier = isOutlier
        self.outlierReason = outlierReason
        self.createdAt = createdAt
    }
}

// MARK: - 2. 每日打卡日志实体 (DailyLog)
public struct DailyLog: Codable, Identifiable, Equatable {
    public var id: String { date }      // 以日期 (YYYY-MM-DD) 作为唯一标识
    public var date: String
    public var flowLevel: Int?          // 1: 少量, 2: 中等, 3: 多, 4: 特多
    public var bbt: Double?             // 基础体温 (e.g. 36.65)
    public var lhTestResult: String?    // 排卵试纸结果 (negative / positive / peak)
    public var cervicalMucus: String?   // 宫颈黏液类型 (dry / sticky / creamy / eggWhite)
    public var symptoms: [String]       // 痛经、头痛、胀痛等标签
    public var moods: [String]          // 情绪标签
    public var notes: String?

    public init(
        date: String,
        flowLevel: Int? = nil,
        bbt: Double? = nil,
        lhTestResult: String? = nil,
        cervicalMucus: String? = nil,
        symptoms: [String] = [],
        moods: [String] = [],
        notes: String? = nil
    ) {
        self.date = date
        self.flowLevel = flowLevel
        self.bbt = bbt
        self.lhTestResult = lhTestResult
        self.cervicalMucus = cervicalMucus
        self.symptoms = symptoms
        self.moods = moods
        self.notes = notes
    }
}

// MARK: - 3. 用户生理基线参数 (UserProfile)
public struct UserProfile: Codable, Equatable {
    public var defaultCycleLength: Int    // 默认周期天数 (默认 28 天)
    public var defaultPeriodLength: Int   // 默认经期天数 (默认 5 天)
    public var lutealPhaseLength: Int    // 默认黄体期天数 (默认 14 天)
    public var isPrivacyLockEnabled: Bool

    public init(
        defaultCycleLength: Int = 28,
        defaultPeriodLength: Int = 5,
        lutealPhaseLength: Int = 14,
        isPrivacyLockEnabled: Bool = false
    ) {
        self.defaultCycleLength = defaultCycleLength
        self.defaultPeriodLength = defaultPeriodLength
        self.lutealPhaseLength = lutealPhaseLength
        self.isPrivacyLockEnabled = isPrivacyLockEnabled
    }
}
