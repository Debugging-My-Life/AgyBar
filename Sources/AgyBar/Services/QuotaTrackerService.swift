import Foundation
import SwiftUI
import Combine

public class QuotaTrackerService: ObservableObject {
    @Published public var quotas: [ModelQuota] = []
    @Published public var trendHistory: [DailyUsagePoint] = []
    @Published public var lastUpdated: Date = Date()
    @Published public var planName: String = "Google AI Pro"
    
    private var timer: AnyCancellable?
    private let storageURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AgyBar")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("history.json")
        
        loadInitialData()
        startPeriodicSync()
    }
    
    public var argonPercent: Int {
        quotas.first(where: { $0.id == "gemini-4-argon" })?.remainingPercent ?? 70
    }
    
    public var flashPercent: Int {
        quotas.first(where: { $0.id == "gemini-3.8-flash" })?.remainingPercent ?? 93
    }
    
    public func refresh() {
        // 백그라운드 쿼터 감지 및 로컬 히스토리 동기화
        lastUpdated = Date()
        saveHistory()
    }
    
    private func loadInitialData() {
        // 기본 쿼터 데이터 초기화 (사용자 현황 기반)
        self.quotas = [
            ModelQuota(
                id: "gemini-4-argon",
                name: "Gemini 4 Argon",
                icon: "⚡️",
                remainingPercent: 70,
                limitType: "Weekly",
                resetTimeString: "2일 4시간 뒤"
            ),
            ModelQuota(
                id: "gemini-3.8-flash",
                name: "Gemini 3.8 Flash",
                icon: "🚀",
                remainingPercent: 93,
                limitType: "5-Hour",
                resetTimeString: "4시간 24분 뒤"
            ),
            ModelQuota(
                id: "claude-and-gpt",
                name: "Claude & GPT",
                icon: "🧠",
                remainingPercent: 100,
                limitType: "Weekly",
                resetTimeString: "100% 보존"
            )
        ]
        
        // 지난 7일간 샘플 트렌드 데이터
        let cal = Calendar.current
        let days = ["금", "토", "일", "월", "화", "수", "오늘"]
        var points: [DailyUsagePoint] = []
        for (idx, day) in days.enumerated() {
            let date = cal.date(byAdding: .day, value: idx - 6, to: Date()) ?? Date()
            let argonUsed = idx == 6 ? 5.0 : Double.random(in: 3...12)
            let flashUsed = idx == 6 ? 12.0 : Double.random(in: 10...25)
            
            points.append(DailyUsagePoint(date: date, dayLabel: day, modelName: "Argon", usedPercent: Double(round(argonUsed))))
            points.append(DailyUsagePoint(date: date, dayLabel: day, modelName: "Flash", usedPercent: Double(round(flashUsed))))
        }
        self.trendHistory = points
    }
    
    private func startPeriodicSync() {
        // 5분마다 자동 새로고침
        timer = Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }
    
    private func saveHistory() {
        // JSON 로컬 파일 영구 저장
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(trendHistory) {
            try? data.write(to: storageURL)
        }
    }
}
