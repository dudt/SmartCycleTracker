import SwiftUI

/// 每日经期关怀与健康洞察服务
public struct CareAdviceService {
    public struct PhaseAdvice {
        public let phaseName: String
        public let iconName: String
        public let themeColor: Color
        public let summary: String
        public let careTips: [String]
    }

    public static func advice(for phaseName: String) -> PhaseAdvice {
        switch phaseName {
        case "月经期":
            return PhaseAdvice(
                phaseName: "月经期",
                iconName: "drop.fill",
                themeColor: Theme.periodRuby,
                summary: "注意保暖，多喝温水与红糖水，避免剧烈运动与受凉。",
                careTips: [
                    "饮食建议：多食用含铁丰富的食物（如红枣、瘦肉），少吃生冷刺激食物。",
                    "运动建议：可进行轻柔的散步或舒缓拉伸，避免高强度有氧运动。",
                    "日常关怀：夜间注意腹部保暖，保证 8 小时优质睡眠。"
                ]
            )
        case "排酸期 / 易孕期", "排酸期":
            return PhaseAdvice(
                phaseName: "排酸期 / 易孕期",
                iconName: "leaf.fill",
                themeColor: Theme.fertileTeal,
                summary: "身体新陈代谢旺盛，处于易孕与排酸黄金窗口期。",
                careTips: [
                    "健康提醒：保持皮肤清洁通风，补充充足的水分与维生素 C。",
                    "饮食建议：多吃新鲜蔬菜水果与优质蛋白（鸡蛋、鱼肉）。",
                    "作息建议：保持规律作息，避免熬夜。"
                ]
            )
        case "排卵日":
            return PhaseAdvice(
                phaseName: "排卵日",
                iconName: "star.fill",
                themeColor: Theme.ovulationGold,
                summary: "今日预测为排卵日，身体精力充沛，心态积极。",
                careTips: [
                    "身体状态：雌激素水平达到高峰，感官敏感度增加。",
                    "健康提示：适当补充叶酸与膳食纤维，保持心情愉悦舒畅。"
                ]
            )
        case "黄体期":
            return PhaseAdvice(
                phaseName: "黄体期",
                iconName: "moon.fill",
                themeColor: Theme.lutealPurple,
                summary: "孕激素分泌上升，身体可能伴有轻微肿胀感或情绪起伏。",
                careTips: [
                    "饮食调理：清淡饮食，减少高盐分摄入，预防身体水肿。",
                    "情绪管理：听轻音乐、做瑜伽放松，保持平和心态。",
                    "皮肤护理：做好基础清洁控油，预防经前痘痘。"
                ]
            )
        default:
            return PhaseAdvice(
                phaseName: "滤泡期 / 安全期",
                iconName: "sun.max.fill",
                themeColor: Theme.safeRose,
                summary: "体力与注意力全面复苏，是工作学习与健身的最佳时期。",
                careTips: [
                    "运动建议：适合安排跑步、力量训练等高效率运动。",
                    "生活建议：大脑思维敏捷，适合处理复杂工作任务。"
                ]
            )
        }
    }
}
