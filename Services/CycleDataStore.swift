import Foundation

/// 本地端侧持久化存储服务 (纯本地，写在 Documents 目录，无数据上传)
public struct CycleDataStore {
    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static var cyclesURL: URL {
        documentsDirectory.appendingPathComponent("history_cycles.json")
    }

    private static var logsURL: URL {
        documentsDirectory.appendingPathComponent("daily_logs.json")
    }

    private static var profileURL: URL {
        documentsDirectory.appendingPathComponent("user_profile.json")
    }

    // MARK: - 历史周期保存与加载
    public static func loadCycles() -> [Cycle] {
        guard let data = try? Data(contentsOf: cyclesURL),
              let cycles = try? JSONDecoder().decode([Cycle].self, from: data) else {
            return []
        }
        return cycles.sorted(by: { $0.startDate < $1.startDate })
    }

    public static func saveCycles(_ cycles: [Cycle]) {
        let sorted = cycles.sorted(by: { $0.startDate < $1.startDate })
        if let data = try? JSONEncoder().encode(sorted) {
            try? data.write(to: cyclesURL)
        }
    }

    // MARK: - 每日日志保存与加载
    public static func loadDailyLogs() -> [String: DailyLog] {
        guard let data = try? Data(contentsOf: logsURL),
              let logs = try? JSONDecoder().decode([String: DailyLog].self, from: data) else {
            return [:]
        }
        return logs
    }

    public static func saveDailyLogs(_ logs: [String: DailyLog]) {
        if let data = try? JSONEncoder().encode(logs) {
            try? data.write(to: logsURL)
        }
    }

    // MARK: - 用户基线参数保存与加载
    public static func loadProfile() -> UserProfile {
        guard let data = try? Data(contentsOf: profileURL),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return profile
    }

    public static func saveProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            try? data.write(to: profileURL)
        }
    }
}
