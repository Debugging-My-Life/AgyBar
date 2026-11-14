import SwiftUI
import AppKit

@main
struct AgyBarApp: App {
    @StateObject private var service = QuotaTrackerService()
    
    init() {
        // 중복 인스턴스 방지 (이미 실행 중인 경우 즉시 종료)
        let bundleID = Bundle.main.bundleIdentifier ?? "com.debuggingmylife.agybar"
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if apps.contains(where: { $0.processIdentifier != currentPID }) {
            exit(0)
        }
        
        // macOS Dock에 아이콘이 뜨지 않고 순수 메뉴바 앱으로만 상주하도록 설정
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(service: service)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "sparkles")
                if service.isConnected || service.hasData {
                    Text("🚀\(service.geminiPercent)% 🧠\(service.claudePercent)% ⚡️\(service.argonPercent)%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                } else {
                    Text("🚀--% 🧠--% ⚡️--%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }
            .foregroundColor(service.isConnected ? .primary : .secondary)
            .opacity(service.isConnected ? 1.0 : 0.65)
        }
        .menuBarExtraStyle(.window)
    }
}
