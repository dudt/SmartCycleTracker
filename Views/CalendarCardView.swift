import SwiftUI

/// 极简月历组件 (纯 SF Symbols 区分月经期、预测经期、排酸期、排卵日、黄体期)
public struct CalendarCardView: View {
    @Binding var selectedDate: Date
    let predictionResult: PredictionResult?
    let historyCycles: [Cycle]
    let dailyLogs: [String: DailyLog]

    @State private var currentMonthOffset: Int = 0

    private let calendar = Calendar.current
    private let daysInWeek = ["日", "一", "二", "三", "四", "五", "六"]

    private var currentMonthDate: Date {
        calendar.date(byAdding: .month, value: currentMonthOffset, to: Date()) ?? Date()
    }

    public init(
        selectedDate: Binding<Date>,
        predictionResult: PredictionResult?,
        historyCycles: [Cycle],
        dailyLogs: [String: DailyLog]
    ) {
        self._selectedDate = selectedDate
        self.predictionResult = predictionResult
        self.historyCycles = historyCycles
        self.dailyLogs = dailyLogs
    }

    public var body: some View {
        VStack(spacing: 14) {
            // 月份切换 Header
            HStack {
                Button(action: { currentMonthOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text(monthYearString(for: currentMonthDate))
                    .font(.system(size: 16, weight: .bold))

                Spacer()

                Button(action: { currentMonthOffset += 1 }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }

            // 星期 Header
            HStack {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日期网格 (Grid)
            let dayItems = generateDaysInMonth(for: currentMonthDate)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(dayItems) { item in
                    if let date = item.date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            predictionResult: predictionResult,
                            historyCycles: historyCycles,
                            dailyLog: dailyLogs[dateString(for: date)]
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }

            // 图例 (Legend - 无 Emoji，纯 SF Symbols 标注)
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    LegendItem(icon: "drop.fill", color: Theme.periodRuby, text: "月经期")
                    LegendItem(icon: "sparkles", color: Theme.predictedPink, text: "预测经期", isBorderOnly: true)
                    LegendItem(icon: "leaf.fill", color: Theme.fertileTeal, text: "排酸期/易孕")
                }
                HStack(spacing: 12) {
                    LegendItem(icon: "star.fill", color: Theme.ovulationGold, text: "排卵日")
                    LegendItem(icon: "moon.fill", color: Theme.lutealPurple, text: "黄体期")
                    LegendItem(icon: "sun.max.fill", color: Theme.safeRose, text: "安全/滤泡期")
                }
            }
            .padding(.top, 6)
        }
        .cardStyle()
    }

    // MARK: - 日期网格单元格
    private struct DayCell: View {
        let date: Date
        let isSelected: Bool
        let predictionResult: PredictionResult?
        let historyCycles: [Cycle]
        let dailyLog: DailyLog?

        private let calendar = Calendar.current

        var isToday: Bool {
            calendar.isDateInToday(date)
        }

        var isActualPeriod: Bool {
            for cycle in historyCycles {
                let start = calendar.startOfDay(for: cycle.startDate)
                let periodLen = cycle.periodLength ?? 5
                if let end = calendar.date(byAdding: .day, value: periodLen - 1, to: start) {
                    if date >= start && date <= end {
                        return true
                    }
                }
            }
            return false
        }

        var isPredictedPeriod: Bool {
            guard let result = predictionResult else { return false }
            let pStart = calendar.startOfDay(for: result.nextPeriodStartDate)
            let pEnd = calendar.startOfDay(for: result.nextPeriodEndDate)
            let cur = calendar.startOfDay(for: date)
            return cur >= pStart && cur <= pEnd
        }

        var isOvulationDay: Bool {
            guard let result = predictionResult else { return false }
            return calendar.isDate(date, inSameDayAs: result.ovulationDate)
        }

        var isFertileWindow: Bool {
            guard let result = predictionResult else { return false }
            let fStart = calendar.startOfDay(for: result.fertileWindowStart)
            let fEnd = calendar.startOfDay(for: result.fertileWindowEnd)
            let cur = calendar.startOfDay(for: date)
            return cur >= fStart && cur <= fEnd
        }

        var body: some View {
            ZStack {
                // 背景形状样式
                if isActualPeriod {
                    Circle()
                        .fill(Theme.periodRuby)
                } else if isPredictedPeriod {
                    Circle()
                        .strokeBorder(Theme.predictedPink, style: StrokeStyle(lineWidth: 1.5, dash: [3]))
                        .background(Circle().fill(Theme.predictedPinkSoft))
                } else if isOvulationDay {
                    Circle()
                        .fill(Theme.ovulationGold)
                } else if isFertileWindow {
                    Circle()
                        .fill(Theme.fertileTealSoft)
                } else if isSelected {
                    Circle()
                        .fill(Color.gray.opacity(0.18))
                }

                // 今日光圈
                if isToday && !isActualPeriod {
                    Circle()
                        .stroke(Theme.periodRuby, lineWidth: 1.5)
                }

                // 日期数字与小图标
                VStack(spacing: 1) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 13, weight: isSelected || isToday ? .bold : .regular))
                        .foregroundColor(isActualPeriod || isOvulationDay ? .white : .primary)

                    // 每日有打卡标记
                    if dailyLog != nil {
                        Circle()
                            .fill(isActualPeriod ? Color.white : Theme.periodRuby)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(height: 36)
        }
    }

    private struct LegendItem: View {
        let icon: String
        let color: Color
        let text: String
        var isBorderOnly: Bool = false

        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)

                Text(text)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func monthYearString(for date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy年 M月"
        return df.string(from: date)
    }

    private func dateString(for date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    private func generateDaysInMonth(for date: Date) -> [CalendarDayItem] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstDayWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        var items: [CalendarDayItem] = []
        var idCounter = 0

        for _ in 0..<(firstDayWeekday - 1) {
            items.append(CalendarDayItem(id: idCounter, date: nil))
            idCounter += 1
        }

        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            items.append(CalendarDayItem(id: idCounter, date: currentDate))
            idCounter += 1
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        return items
    }
}

struct CalendarDayItem: Identifiable {
    let id: Int
    let date: Date?
}
