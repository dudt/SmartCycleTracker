import SwiftUI

/// 首页核心：当前周期状态环形轮盘
public struct CycleWheelView: View {
    let currentDayInCycle: Int
    let totalPredictedCycleLength: Int
    let phaseName: String
    let countdownDays: Int
    let predictionResult: PredictionResult?
    let onQuickLogTap: () -> Void

    public init(
        currentDayInCycle: Int = 12,
        totalPredictedCycleLength: Int = 28,
        phaseName: String = "滤泡期 / 安全期",
        countdownDays: Int = 16,
        predictionResult: PredictionResult? = nil,
        onQuickLogTap: @escaping () -> Void
    ) {
        self.currentDayInCycle = currentDayInCycle
        self.totalPredictedCycleLength = totalPredictedCycleLength
        self.phaseName = phaseName
        self.countdownDays = countdownDays
        self.predictionResult = predictionResult
        self.onQuickLogTap = onQuickLogTap
    }

    private var progress: Double {
        min(1.0, max(0.05, Double(currentDayInCycle) / Double(max(1, totalPredictedCycleLength))))
    }

    public var body: some View {
        VStack(spacing: 20) {
            // 预测区间顶部 Banner
            if let result = predictionResult {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Theme.periodRuby)
                    
                    let formatter: DateFormatter = {
                        let df = DateFormatter()
                        df.dateFormat = "M月d日"
                        return df
                    }()
                    
                    Text("智能预测下次月经：\(formatter.string(from: result.nextPeriodStartDate)) (±\(String(format: "%.1f", result.confidenceMarginDays))天)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary.opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.periodRubySoft)
                .cornerRadius(16)
            }

            // 核心环形进度轮盘
            ZStack {
                // 背景灰圈
                Circle()
                    .stroke(Color.gray.opacity(0.12), lineWidth: 18)
                    .frame(width: 220, height: 220)

                // 进度外圈 (渐变色彩)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Theme.periodRuby, Theme.lutealPurple, Theme.fertileTeal]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 220, height: 220)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)

                // 轮盘中央内容
                VStack(spacing: 6) {
                    Text(phaseName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.fertileTeal)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("第")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        Text("\(currentDayInCycle)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("天")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }

                    Text("距下次经期约 \(countdownDays) 天")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)

            // 快捷记一笔 Button
            Button(action: onQuickLogTap) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("记一笔今日状态")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Theme.periodRuby, Theme.periodRuby.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: Theme.periodRuby.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .cardStyle()
    }
}
