import SwiftUI

/// 应用主题设计规范与色彩集
public enum Theme {
    // 经期红 (Period Ruby)
    public static let periodRuby = Color(red: 0.92, green: 0.28, blue: 0.42)
    public static let periodRubySoft = Color(red: 0.98, green: 0.88, blue: 0.90)
    
    // 易孕期绿/青 (Fertile Teal)
    public static let fertileTeal = Color(red: 0.20, green: 0.68, blue: 0.65)
    public static let fertileTealSoft = Color(red: 0.88, green: 0.96, blue: 0.95)
    
    // 排卵金 (Ovulation Gold)
    public static let ovulationGold = Color(red: 0.95, green: 0.70, blue: 0.22)
    
    // 黄体期紫色 (Luteal Purple)
    public static let lutealPurple = Color(red: 0.58, green: 0.42, blue: 0.85)
    
    // 背景与卡片 (Backgrounds & Cards)
    public static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.98, green: 0.96, blue: 0.97), Color(red: 0.95, green: 0.93, blue: 0.96)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let cardBackground = Color.white.opacity(0.85)
}

// 卡片阴影与圆角修饰符
struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyleModifier())
    }
}
