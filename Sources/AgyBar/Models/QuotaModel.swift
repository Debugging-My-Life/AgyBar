import Foundation
import SwiftUI

public struct ModelQuota: Identifiable, Codable {
    public let id: String
    public var name: String
    public var icon: String
    public var remainingPercent: Int
    public var limitType: String
    public var resetTimeString: String
    
    public init(id: String, name: String, icon: String, remainingPercent: Int, limitType: String, resetTimeString: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.remainingPercent = remainingPercent
        self.limitType = limitType
        self.resetTimeString = resetTimeString
    }
    
    public var statusColor: Color {
        if remainingPercent >= 80 {
            return .green
        } else if remainingPercent >= 40 {
            return .yellow
        } else {
            return .red
        }
    }
}

public struct DailyUsagePoint: Identifiable, Codable {
    public var id = UUID()
    public var date: Date
    public var dayLabel: String
    public var modelName: String
    public var usedPercent: Double
    
    public init(id: UUID = UUID(), date: Date, dayLabel: String, modelName: String, usedPercent: Double) {
        self.id = id
        self.date = date
        self.dayLabel = dayLabel
        self.modelName = modelName
        self.usedPercent = usedPercent
    }
}
