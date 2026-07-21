import SwiftUI

/// 思雨经期助手 — 全局视觉与设计系统
public enum Theme {
    // 1. 月经期 (Period Phase) — 深玫瑰红
    public static let periodRuby = Color(red: 0.90, green: 0.22, blue: 0.21)
    public static let periodRubySoft = Color(red: 0.98, green: 0.88, blue: 0.90)
    
    // 2. 预测经期 (Predicted Period) — 柔和粉红
    public static let predictedPink = Color(red: 0.93, green: 0.35, blue: 0.58)
    public static let predictedPinkSoft = Color(red: 0.99, green: 0.90, blue: 0.94)

    // 3. 排酸期 / 易孕期 (Fertile Window) — 薄荷碧绿
    public static let fertileTeal = Color(red: 0.0, green: 0.54, blue: 0.48)
    public static let fertileTealSoft = Color(red: 0.88, green: 0.96, blue: 0.95)

    // 4. 排卵日 (Ovulation Day) — 琥珀金光
    public static let ovulationGold = Color(red: 1.0, green: 0.63, blue: 0.0)
    public static let ovulationGoldSoft = Color(red: 1.0, green: 0.96, blue: 0.85)

    // 5. 黄体期 (Luteal Phase) — 优雅熏衣紫
    public static let lutealPurple = Color(red: 0.49, green: 0.34, blue: 0.76)
    public static let lutealPurpleSoft = Color(red: 0.93, green: 0.90, blue: 0.97)

    // 6. 滤泡期 / 安全期 (Follicular / Safe Phase) — 暖粉玫瑰
    public static let safeRose = Color(red: 0.85, green: 0.11, blue: 0.38)
    public static let safeRoseSoft = Color(red: 0.97, green: 0.85, blue: 0.90)

    // 背景柔滑高雅渐变
    public static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.99, green: 0.97, blue: 0.98),
            Color(red: 0.96, green: 0.94, blue: 0.96)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let cardBackground = Color.white.opacity(0.92)
}

// 高质感毛玻璃与柔和卡片阴影
struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 5)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyleModifier())
    }
}
