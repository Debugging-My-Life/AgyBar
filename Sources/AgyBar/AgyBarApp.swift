import SwiftUI
import AppKit

@main
struct AgyBarApp: App {
    @StateObject private var service = QuotaTrackerService()
    
    init() {
        // macOS Dock에 아이콘이 뜨지 않고 순수 메뉴바 앱으로만 상주하도록 설정
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(service: service)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "sparkles")
                Text("⚡️\(service.argonPercent)% 🚀\(service.flashPercent)%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)
    }
}
