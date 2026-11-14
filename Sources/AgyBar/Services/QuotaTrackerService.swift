import Foundation
import SwiftUI
import Combine
import Darwin

@MainActor
public class QuotaTrackerService: ObservableObject {
    @Published public var groups: [ModelGroup] = []
    @Published public var trendHistory: [DailyUsagePoint] = []
    @Published public var lastUpdated: Date = Date()
    @Published public var planName: String = "Pro"
    @Published public var promptCredits: Int? = nil
    @Published public var flowCredits: Int? = nil
    @Published public var isConnected: Bool = false
    @Published public var isLoading: Bool = false
    
    private var dailyRecords: [DailyUsageRecord] = []
    private var timer: AnyCancellable?
    private let storageURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AgyBar")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("history.json")
        
        loadCachedData()
        startPeriodicSync()
        refresh()
    }
    
    // MARK: - Computed Properties for Quick UI Access
    public var geminiGroup: ModelGroup? {
        groups.first(where: { $0.id == "gemini" })
    }
    
    public var claudeGroup: ModelGroup? {
        groups.first(where: { $0.id == "claude" })
    }
    
    public var argonGroup: ModelGroup? {
        groups.first(where: { $0.id == "argon" })
    }
    
    public var geminiPercent: Int {
        geminiGroup?.minRemainingPercent ?? 100
    }
    
    public var claudePercent: Int {
        claudeGroup?.minRemainingPercent ?? 100
    }
    
    public var argonPercent: Int {
        argonGroup?.minRemainingPercent ?? 100
    }
    
    public var hasData: Bool {
        !groups.isEmpty
    }
    
    // MARK: - Public Refresh API
    public func refresh() {
        Task {
            await self.fetchData()
        }
    }
    
    // MARK: - Private Daemon Discovery & API Fetch
    private func fetchData() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        guard let hub = findActiveDaemonHub() else {
            self.isConnected = false
            return
        }
        
        async let quotaTask: QuotaSummaryResponse? = requestAPI(
            port: hub.httpPort,
            csrfToken: hub.csrfToken,
            endpoint: "RetrieveUserQuotaSummary"
        )
        async let userTask: UserStatusResponse? = requestAPI(
            port: hub.httpPort,
            csrfToken: hub.csrfToken,
            endpoint: "GetUserStatus"
        )
        
        let (quotaResponse, userResponse) = await (quotaTask, userTask)
        
        guard let quotaSummary = quotaResponse else {
            self.isConnected = false
            return
        }
        
        self.isConnected = true
        self.lastUpdated = Date()
        
        // Parse Plan & Credits
        if let userStatus = userResponse?.userStatus {
            if let pName = userStatus.planStatus?.planInfo?.planName, !pName.isEmpty {
                self.planName = pName
            }
            self.promptCredits = userStatus.planStatus?.availablePromptCredits
            self.flowCredits = userStatus.planStatus?.availableFlowCredits
        }
        
        // Parse Quota Groups
        var parsedGroups: [ModelGroup] = []
        if let rawGroups = quotaSummary.response.groups {
            for raw in rawGroups {
                let name = raw.displayName
                let buckets = (raw.buckets ?? []).map { b in
                    QuotaBucket(
                        bucketId: b.bucketId,
                        displayName: b.displayName,
                        window: b.window ?? "weekly",
                        remainingFraction: b.remainingFraction ?? 1.0,
                        resetTime: b.resetTime ?? ""
                    )
                }
                
                if name.localizedCaseInsensitiveContains("Argon") {
                    parsedGroups.append(ModelGroup(
                        id: "argon",
                        name: "Gemini 4 Argon",
                        icon: "⚡️",
                        subtext: "Argon Dedicated Quota",
                        buckets: buckets
                    ))
                } else if name.localizedCaseInsensitiveContains("Claude") || name.localizedCaseInsensitiveContains("GPT") {
                    parsedGroups.append(ModelGroup(
                        id: "claude",
                        name: "Claude & GPT",
                        icon: "🧠",
                        subtext: "Sonnet / Opus / GPT-OSS",
                        buckets: buckets
                    ))
                } else if name.localizedCaseInsensitiveContains("Gemini") {
                    parsedGroups.append(ModelGroup(
                        id: "gemini",
                        name: "Gemini Models",
                        icon: "🚀",
                        subtext: "Flash / Pro / Hydrogen",
                        buckets: buckets
                    ))
                }
            }
        }
        
        // Standard Bento ordering: Gemini -> Claude -> Argon
        let order = ["gemini", "claude", "argon"]
        self.groups = order.compactMap { id in parsedGroups.first(where: { $0.id == id }) }
        
        // Update daily usage tracking
        updateDailyHistory()
        
        // Save persistent cache
        saveCache()
    }
    
    private func findActiveDaemonHub() -> DaemonHubInfo? {
        let daemonDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".gemini/antigravity/daemon")
        
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: daemonDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return nil
        }
        
        let hubFiles = files
            .filter { $0.lastPathComponent.hasPrefix("hub_") && $0.pathExtension == "json" }
            .sorted { u1, u2 in
                let d1 = (try? u1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let d2 = (try? u2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return d1 > d2
            }
        
        for file in hubFiles {
            guard let data = try? Data(contentsOf: file),
                  let hub = try? JSONDecoder().decode(DaemonHubInfo.self, from: data) else {
                continue
            }
            if Darwin.kill(pid_t(hub.pid), 0) == 0 {
                return hub
            }
        }
        
        return nil
    }
    
    private func requestAPI<T: Decodable>(port: Int, csrfToken: String, endpoint: String) async -> T? {
        guard let url = URL(string: "http://127.0.0.1:\(port)/exa.language_server_pb.LanguageServerService/\(endpoint)") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(csrfToken, forHTTPHeaderField: "x-codeium-csrf-token")
        request.httpBody = Data("{}".utf8)
        request.timeoutInterval = 5
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
    
    // MARK: - Daily Usage History Tracking
    private func updateDailyHistory() {
        let now = Date()
        let dateKeyFormatter = DateFormatter()
        dateKeyFormatter.dateFormat = "yyyy-MM-dd"
        dateKeyFormatter.locale = Locale(identifier: "en_US_POSIX")
        let todayKey = dateKeyFormatter.string(from: now)
        
        let geminiUsed = Double(max(0, 100 - geminiPercent))
        let claudeUsed = Double(max(0, 100 - claudePercent))
        let argonUsed = Double(max(0, 100 - argonPercent))
        
        if let idx = dailyRecords.firstIndex(where: { $0.dateKey == todayKey }) {
            dailyRecords[idx].geminiUsed = max(dailyRecords[idx].geminiUsed, geminiUsed)
            dailyRecords[idx].claudeUsed = max(dailyRecords[idx].claudeUsed, claudeUsed)
            dailyRecords[idx].argonUsed = max(dailyRecords[idx].argonUsed, argonUsed)
        } else {
            let newRecord = DailyUsageRecord(
                dateKey: todayKey,
                date: now,
                geminiUsed: geminiUsed,
                claudeUsed: claudeUsed,
                argonUsed: argonUsed
            )
            dailyRecords.append(newRecord)
        }
        
        dailyRecords.sort { $0.dateKey < $1.dateKey }
        if dailyRecords.count > 7 {
            dailyRecords = Array(dailyRecords.suffix(7))
        }
        
        rebuildTrendHistory()
    }
    
    private func rebuildTrendHistory() {
        let now = Date()
        let dateKeyFormatter = DateFormatter()
        dateKeyFormatter.dateFormat = "yyyy-MM-dd"
        dateKeyFormatter.locale = Locale(identifier: "en_US_POSIX")
        let todayKey = dateKeyFormatter.string(from: now)
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        dayFormatter.locale = Locale(identifier: "ko_KR")
        
        var points: [DailyUsagePoint] = []
        for record in dailyRecords {
            let isToday = (record.dateKey == todayKey)
            let label = isToday ? "오늘" : dayFormatter.string(from: record.date)
            points.append(DailyUsagePoint(date: record.date, dayLabel: label, modelName: "Gemini", usedPercent: record.geminiUsed))
            points.append(DailyUsagePoint(date: record.date, dayLabel: label, modelName: "Claude/GPT", usedPercent: record.claudeUsed))
            points.append(DailyUsagePoint(date: record.date, dayLabel: label, modelName: "Argon", usedPercent: record.argonUsed))
        }
        self.trendHistory = points
    }
    
    // MARK: - Periodic Background Sync (60s)
    private func startPeriodicSync() {
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }
    
    // MARK: - Local Cache Persistence
    private func saveCache() {
        let cache = AppCacheData(
            lastUpdated: lastUpdated,
            planName: planName,
            promptCredits: promptCredits,
            flowCredits: flowCredits,
            groups: groups,
            records: dailyRecords
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(cache) {
            try? data.write(to: storageURL)
        }
    }
    
    private func loadCachedData() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        
        // 1. Try decoding standard AppCacheData
        if let cache = try? JSONDecoder().decode(AppCacheData.self, from: data) {
            self.lastUpdated = cache.lastUpdated
            self.planName = cache.planName
            self.promptCredits = cache.promptCredits
            self.flowCredits = cache.flowCredits
            self.groups = cache.groups
            self.dailyRecords = cache.records
            rebuildTrendHistory()
            return
        }
        
        // 2. Fallback: migrate legacy [DailyUsagePoint]
        if let legacyPoints = try? JSONDecoder().decode([DailyUsagePoint].self, from: data) {
            var recordsMap: [String: DailyUsageRecord] = [:]
            let dateKeyFormatter = DateFormatter()
            dateKeyFormatter.dateFormat = "yyyy-MM-dd"
            dateKeyFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            for point in legacyPoints {
                let key = dateKeyFormatter.string(from: point.date)
                var rec = recordsMap[key] ?? DailyUsageRecord(
                    dateKey: key,
                    date: point.date,
                    geminiUsed: 0,
                    claudeUsed: 0,
                    argonUsed: 0
                )
                if point.modelName == "Flash" || point.modelName == "Gemini" {
                    rec.geminiUsed = point.usedPercent
                } else if point.modelName == "Argon" {
                    rec.argonUsed = point.usedPercent
                } else if point.modelName.contains("Claude") {
                    rec.claudeUsed = point.usedPercent
                }
                recordsMap[key] = rec
            }
            self.dailyRecords = recordsMap.values.sorted { $0.dateKey < $1.dateKey }
            rebuildTrendHistory()
        }
    }
}
