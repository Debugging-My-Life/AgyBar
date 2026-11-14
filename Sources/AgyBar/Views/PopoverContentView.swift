import SwiftUI
import AppKit

public struct PopoverContentView: View {
    @ObservedObject public var service: QuotaTrackerService
    
    public init(service: QuotaTrackerService) {
        self.service = service
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // MARK: - 1. Header
            headerView
            
            // MARK: - 2. Bento Cards (3 Groups)
            bentoCardsView
            
            // MARK: - 3. Daily Usage Trend Chart
            UsageTrendChartView(usagePoints: service.trendHistory)
            
            // MARK: - 4. Dynamic Smart Tip
            smartTipView
            
            Divider()
                .opacity(0.6)
            
            // MARK: - 5. Footer Quick Actions
            footerView
        }
        .padding(14)
        .frame(width: 350)
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .font(.system(size: 13, weight: .bold))
                Text("Antigravity Quota")
                    .font(.system(size: 13, weight: .bold))
                
                // Live / Offline Status Indicator
                HStack(spacing: 3) {
                    Circle()
                        .fill(service.isConnected ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    Text(service.isConnected ? "Live" : "Offline")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(service.isConnected ? .green : .secondary)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(service.isConnected ? Color.green.opacity(0.12) : Color.primary.opacity(0.06))
                .cornerRadius(4)
            }
            
            Spacer()
            
            // Plan Badge
            Text(service.planName)
                .font(.system(size: 9.5, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(service.isConnected ? Color.blue.opacity(0.12) : Color.primary.opacity(0.06))
                .foregroundColor(service.isConnected ? .blue : .secondary)
                .cornerRadius(4)
            
            // Credits Summary Badge (Prompt / Flow)
            if service.promptCredits != nil || service.flowCredits != nil {
                HStack(spacing: 3) {
                    Text("P: \(service.promptCredits ?? 0)")
                    Text("•").foregroundColor(.secondary.opacity(0.6))
                    Text("F: \(service.flowCredits ?? 0)")
                }
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(4)
            }
            
            // Refresh Button with Rotation Animation
            Button(action: {
                service.refresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(service.isLoading ? 360 : 0))
                    .animation(
                        service.isLoading
                            ? Animation.linear(duration: 0.8).repeatForever(autoreverses: false)
                            : .default,
                        value: service.isLoading
                    )
            }
            .buttonStyle(.plain)
            .help("지금 새로고침 (60초 주기 자동 갱신)")
        }
        .padding(.horizontal, 2)
    }
    
    private var bentoCardsView: some View {
        VStack(spacing: 8) {
            if let gemini = service.geminiGroup {
                DualGaugeBentoCard(group: gemini, isOffline: !service.isConnected)
            }
            
            if let claude = service.claudeGroup {
                DualGaugeBentoCard(group: claude, isOffline: !service.isConnected)
            }
            
            if let argon = service.argonGroup {
                ArgonWideBentoCard(group: argon, isOffline: !service.isConnected)
            }
            
            if service.groups.isEmpty {
                VStack(spacing: 8) {
                    if service.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("쿼터 정보를 불러오는 중...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary.opacity(0.7))
                        Text("Antigravity 미실행 (Offline)")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("Antigravity를 실행하면 60초 내 자동 연결됩니다.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.8))
                        Button(action: { service.refresh() }) {
                            Label("다시 연결", systemImage: "arrow.clockwise")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color.primary.opacity(0.02))
                .cornerRadius(10)
            }
        }
    }
    
    private var smartTipView: some View {
        HStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)
                .font(.system(size: 10.5))
            Text(smartTipText)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
        }
        .padding(.horizontal, 2)
    }
    
    private var footerView: some View {
        HStack {
            Button(action: {
                let appURL = URL(fileURLWithPath: "/Applications/Antigravity.app")
                NSWorkspace.shared.open(appURL)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.forward.app")
                    Text("Antigravity 열기")
                }
                .font(.system(size: 10.5, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
            
            Spacer()
            
            Text("업데이트: \(formattedLastUpdated)")
                .font(.system(size: 9.5))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("종료")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 2)
    }
    
    private var formattedLastUpdated: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: service.lastUpdated)
    }
    
    private var smartTipText: String {
        if !service.isConnected && !service.hasData {
            return "Antigravity 데몬에 연결되지 않았습니다. Antigravity를 실행해 주세요."
        }
        let argon = service.argonPercent
        let gemini = service.geminiPercent
        let claude = service.claudePercent
        
        if argon <= 25 {
            return "⚡️ Argon 소진 임박(\(argon)%). 대화 및 일반 작업은 Gemini 또는 Claude 활용 권장"
        } else if gemini <= 30 && claude > 50 {
            return "🚀 Gemini 잔여 \(gemini)%. 여유 있는 Claude & GPT(\(claude)%) 활용 권장"
        } else if claude <= 30 && gemini > 50 {
            return "🧠 Claude & GPT 잔여 \(claude)%. Gemini Flash/Pro(\(gemini)%) 활용 권장"
        } else if argon == 100 && gemini == 100 && claude == 100 {
            return "✨ 모든 모델 쿼터가 100% 최상의 상태입니다. 마음껏 작업하세요!"
        } else {
            return "💡 쿼터 상태 양호: Argon \(argon)%, Gemini \(gemini)%, Claude \(claude)%"
        }
    }
}

// MARK: - Bento Card 1 & 2: Dual Gauge Layout (Weekly + 5-Hour)
struct DualGaugeBentoCard: View {
    let group: ModelGroup
    var isOffline: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack(spacing: 4) {
                Text(group.icon)
                    .font(.system(size: 11))
                Text(group.name)
                    .font(.system(size: 11.5, weight: .bold))
                Spacer()
                Text(group.subtext)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                // Weekly Limit Gauge
                if let weekly = group.weeklyBucket {
                    gaugeColumn(
                        title: "Weekly Limit",
                        bucket: weekly
                    )
                } else {
                    placeholderColumn(title: "Weekly")
                }
                
                Divider()
                    .frame(height: 44)
                    .opacity(0.4)
                
                // 5-Hour Limit Gauge
                if let fiveH = group.fiveHourBucket {
                    gaugeColumn(
                        title: "5-Hour Limit",
                        bucket: fiveH
                    )
                } else {
                    placeholderColumn(title: "5-Hour")
                }
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.035))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
    
    private func gaugeColumn(title: String, bucket: QuotaBucket) -> some View {
        let displayColor: Color = isOffline ? Color.gray.opacity(0.65) : bucket.statusColor
        return HStack(spacing: 8) {
            CircularGaugeView(
                percent: bucket.remainingPercent,
                color: displayColor,
                lineWidth: 3.8,
                size: 42
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.primary.opacity(isOffline ? 0.65 : 0.85))
                
                Text("\(bucket.remainingPercent)% 잔여")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(isOffline ? .secondary : bucket.statusColor)
                
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 7.5))
                    Text(bucket.formattedResetCountdown)
                        .font(.system(size: 8.5))
                        .lineLimit(1)
                }
                .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func placeholderColumn(title: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(.secondary)
            Text("--")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bento Card 3: Argon Wide Card Layout
struct ArgonWideBentoCard: View {
    let group: ModelGroup
    var isOffline: Bool = false
    
    var body: some View {
        let weekly = group.weeklyBucket ?? group.buckets.first
        let remainingPercent = weekly?.remainingPercent ?? group.minRemainingPercent
        let rawStatusColor = weekly?.statusColor ?? .green
        let displayColor: Color = isOffline ? Color.gray.opacity(0.65) : rawStatusColor
        let resetCountdown = weekly?.formattedResetCountdown ?? "-"
        
        VStack(spacing: 8) {
            // Header
            HStack(spacing: 4) {
                Text(group.icon)
                    .font(.system(size: 11))
                Text(group.name)
                    .font(.system(size: 11.5, weight: .bold))
                Spacer()
                Text("Argon Dedicated Quota")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                // Circular Gauge
                CircularGaugeView(
                    percent: remainingPercent,
                    color: displayColor,
                    lineWidth: 4.2,
                    size: 46
                )
                
                // Details + Progress Bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Weekly Limit")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.primary.opacity(isOffline ? 0.65 : 0.85))
                        Spacer()
                        Text("\(remainingPercent)% 잔여")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(isOffline ? .secondary : rawStatusColor)
                    }
                    
                    // Capsule Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 6)
                            Capsule()
                                .fill(displayColor)
                                .frame(
                                    width: geo.size.width * CGFloat(max(0, min(100, remainingPercent))) / 100.0,
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 8))
                        Text(resetCountdown)
                            .font(.system(size: 8.5))
                        Spacer()
                        Text("High / Medium / Low")
                            .font(.system(size: 8.5))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.035))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}
