import SwiftUI

public struct PopoverContentView: View {
    @ObservedObject public var service: QuotaTrackerService
    
    public init(service: QuotaTrackerService) {
        self.service = service
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .bold))
                    Text("Antigravity Quota")
                        .font(.system(size: 13, weight: .bold))
                }
                Spacer()
                
                Text(service.planName)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
                Button(action: {
                    service.refresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            // Quota Cards Grid
            HStack(spacing: 8) {
                ForEach(service.quotas) { quota in
                    VStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Text(quota.icon)
                                .font(.system(size: 10))
                            Text(quota.name.replacingOccurrences(of: "Gemini ", with: ""))
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        
                        CircularGaugeView(
                            percent: quota.remainingPercent,
                            color: quota.statusColor,
                            lineWidth: 4,
                            size: 44
                        )
                        
                        VStack(spacing: 1) {
                            Text(quota.limitType)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Text(quota.resetTimeString)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.primary.opacity(0.8))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            
            // 7-day Trend Chart
            UsageTrendChartView(usagePoints: service.trendHistory)
            
            // Smart Tip
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 11))
                Text("Argon 잔여 70%. 메인 세션은 Flash(93%)로 유지 권장")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            Divider()
            
            // Footer Quick Actions
            HStack {
                Button(action: {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Antigravity.app"))
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Antigravity 열기")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("종료")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .frame(width: 320)
    }
}
