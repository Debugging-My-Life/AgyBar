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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("소모량 %")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Chart(usagePoints) { point in
                BarMark(
                    x: .value("Day", point.dayLabel),
                    y: .value("Used", point.usedPercent)
                )
                .foregroundStyle(by: .value("Model", point.modelName))
                .cornerRadius(3)
            }
            .chartForegroundStyleScale([
                "Argon": Color.orange,
                "Flash": Color.green,
                "Claude": Color.blue
            ])
            .chartLegend(position: .top, alignment: .trailing, spacing: 8)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel() {
                        if let intVal = value.as(Int.self) {
                            Text("\(intVal)%").font(.system(size: 9))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().font(.system(size: 10, weight: .medium))
                }
            }
            .frame(height: 110)
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
