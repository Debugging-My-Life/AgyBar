import SwiftUI

public struct CircularGaugeView: View {
    public let percent: Int
    public let color: Color
    public var lineWidth: CGFloat = 4.5
    public var size: CGFloat = 52
    
    public init(percent: Int, color: Color, lineWidth: CGFloat = 4.5, size: CGFloat = 52) {
        self.percent = percent
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: lineWidth)
            
            // Progress Ring
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(100, percent))) / 100.0)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: percent)
            
            // Percentage Label
            Text(percent >= 0 ? "\(percent)%" : "--%")
                .font(.system(size: size * 0.27, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(width: size, height: size)
    }
}
