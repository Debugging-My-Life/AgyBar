import SwiftUI
import Charts

public struct UsageTrendChartView: View {
    public let usagePoints: [DailyUsagePoint]
    
    public init(usagePoints: [DailyUsagePoint]) {
        self.usagePoints = usagePoints
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("📈 데일리 소모 추이 (지난 7일)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("소모량 %")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            if usagePoints.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("충분한 사용 기록이 누적되면 7일간의 소모 추이가 표시됩니다")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 95)
            } else {
                Chart(usagePoints) { point in
                    BarMark(
                        x: .value("Day", point.dayLabel),
                        y: .value("Used", point.usedPercent)
                    )
                    .foregroundStyle(by: .value("Model", point.modelName))
                    .cornerRadius(2.5)
                }
                .chartForegroundStyleScale([
                    "Gemini": Color.green,
                    "Claude/GPT": Color.blue,
                    "Argon": Color.orange
                ])
                .chartLegend(position: .top, alignment: .trailing, spacing: 8)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Color.primary.opacity(0.06))
                        AxisValueLabel() {
                            if let intVal = value.as(Int.self) {
                                Text("\(intVal)%").font(.system(size: 8.5))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.system(size: 9, weight: .medium))
                    }
                }
                .frame(height: 100)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}
