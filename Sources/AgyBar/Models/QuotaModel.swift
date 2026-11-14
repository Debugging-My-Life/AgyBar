import Foundation
import SwiftUI

// MARK: - Daemon Hub Info
public struct DaemonHubInfo: Codable {
    public let pid: Int
    public let httpPort: Int
    public let csrfToken: String
    
    public init(pid: Int, httpPort: Int, csrfToken: String) {
        self.pid = pid
        self.httpPort = httpPort
        self.csrfToken = csrfToken
    }
}

// MARK: - ConnectRPC Quota API Response Models
public struct QuotaSummaryResponse: Decodable {
    public let response: QuotaSummaryPayload
}

public struct QuotaSummaryPayload: Decodable {
    public let groups: [QuotaGroupRaw]?
    public let description: String?
}

public struct QuotaGroupRaw: Decodable {
    public let displayName: String
    public let description: String?
    public let buckets: [QuotaBucketRaw]?
}

public struct QuotaBucketRaw: Decodable {
    public let bucketId: String
    public let displayName: String
    public let window: String?
    public let remainingFraction: Double?
    public let resetTime: String?
}

// MARK: - ConnectRPC User Status API Response Models
public struct UserStatusResponse: Decodable {
    public let userStatus: UserStatusData?
}

public struct UserStatusData: Decodable {
    public let planStatus: PlanStatusData?
}

public struct PlanStatusData: Decodable {
    public let planInfo: PlanInfoData?
    public let availablePromptCredits: Int?
    public let availableFlowCredits: Int?
}

public struct PlanInfoData: Decodable {
    public let planName: String?
    public let teamsTier: String?
}

// MARK: - Domain UI Models
public enum ModelQuotaHelper {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    
    private static let isoFormatterWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    
    public static func parseISO8601(_ string: String) -> Date? {
        if let d = isoFormatter.date(from: string) { return d }
        return isoFormatterWithFraction.date(from: string)
    }
    
    public static func formatCountdown(from resetTime: String) -> String {
        guard let targetDate = parseISO8601(resetTime) else {
            return resetTime.isEmpty ? "-" : resetTime
        }
        let diff = targetDate.timeIntervalSince(Date())
        if diff <= 0 {
            return "리셋 완료"
        }
        let totalSeconds = Int(diff)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if days > 0 {
            if hours > 0 {
                return "\(days)일 \(hours)시간 뒤"
            } else {
                return "\(days)일 뒤"
            }
        } else if hours > 0 {
            if minutes > 0 {
                return "\(hours)시간 \(minutes)분 뒤"
            } else {
                return "\(hours)시간 뒤"
            }
        } else if minutes > 0 {
            return "\(minutes)분 뒤"
        } else {
            return "곧 리셋"
        }
    }
}

public struct QuotaBucket: Identifiable, Codable {
    public var id: String { bucketId }
    public let bucketId: String
    public let displayName: String
    public let window: String // "weekly", "5h"
    public let remainingFraction: Double
    public let remainingPercent: Int
    public let resetTime: String
    
    public init(bucketId: String, displayName: String, window: String, remainingFraction: Double, resetTime: String) {
        self.bucketId = bucketId
        self.displayName = displayName
        self.window = window
        self.remainingFraction = remainingFraction
        self.remainingPercent = Int(round(max(0.0, min(1.0, remainingFraction)) * 100))
        self.resetTime = resetTime
    }
    
    public var formattedResetCountdown: String {
        ModelQuotaHelper.formatCountdown(from: resetTime)
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

public struct ModelGroup: Identifiable, Codable {
    public let id: String // "gemini", "claude", "argon"
    public let name: String
    public let icon: String
    public let subtext: String
    public var buckets: [QuotaBucket]
    
    public init(id: String, name: String, icon: String, subtext: String, buckets: [QuotaBucket]) {
        self.id = id
        self.name = name
        self.icon = icon
        self.subtext = subtext
        self.buckets = buckets
    }
    
    public var weeklyBucket: QuotaBucket? {
        buckets.first(where: { $0.window.lowercased() == "weekly" })
    }
    
    public var fiveHourBucket: QuotaBucket? {
        buckets.first(where: { $0.window.lowercased() == "5h" })
    }
    
    public var minRemainingPercent: Int {
        buckets.map(\.remainingPercent).min() ?? 100
    }
}

// MARK: - Daily Usage History Points
public struct DailyUsagePoint: Identifiable, Codable {
    public var id = UUID()
    public var date: Date
    public var dayLabel: String
    public var modelName: String // "Gemini", "Claude/GPT", "Argon"
    public var usedPercent: Double
    
    public init(id: UUID = UUID(), date: Date, dayLabel: String, modelName: String, usedPercent: Double) {
        self.id = id
        self.date = date
        self.dayLabel = dayLabel
        self.modelName = modelName
        self.usedPercent = usedPercent
    }
}

public struct DailyUsageRecord: Codable {
    public let dateKey: String // "yyyy-MM-dd"
    public let date: Date
    public var geminiUsed: Double
    public var claudeUsed: Double
    public var argonUsed: Double
    
    public init(dateKey: String, date: Date, geminiUsed: Double, claudeUsed: Double, argonUsed: Double) {
        self.dateKey = dateKey
        self.date = date
        self.geminiUsed = geminiUsed
        self.claudeUsed = claudeUsed
        self.argonUsed = argonUsed
    }
}

// MARK: - App Cache Data for Offline Persistence
public struct AppCacheData: Codable {
    public var lastUpdated: Date
    public var planName: String
    public var promptCredits: Int?
    public var flowCredits: Int?
    public var groups: [ModelGroup]
    public var records: [DailyUsageRecord]
    
    public init(lastUpdated: Date, planName: String, promptCredits: Int?, flowCredits: Int?, groups: [ModelGroup], records: [DailyUsageRecord]) {
        self.lastUpdated = lastUpdated
        self.planName = planName
        self.promptCredits = promptCredits
        self.flowCredits = flowCredits
        self.groups = groups
        self.records = records
    }
}
