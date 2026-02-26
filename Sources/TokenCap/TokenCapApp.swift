import SwiftUI

@main
struct TokenCapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var usageService = UsageService()
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var notifications = NotificationService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(service: usageService, settings: settings)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: menuBarIcon)
                .symbolRenderingMode(.palette)
                .foregroundStyle(menuBarIconColor, .primary)
            Text(usageService.menuBarText)
                .font(.caption.monospacedDigit())
        }
        .onAppear {
            notifications.requestPermission()
            usageService.startPolling(interval: settings.pollInterval)
        }
        .onChange(of: settings.pollInterval) { _, newInterval in
            usageService.startPolling(interval: newInterval)
        }
        .onChange(of: usageService.lastUpdated) { _, _ in
            if let usage = usageService.usage {
                notifications.checkThresholds(usage: usage, settings: settings)
            }
        }
    }

    // MARK: - Menu Bar Icon

    private var menuBarIcon: String {
        switch usageService.sessionUsageLevel {
        case .low: return "gauge.with.needle"
        case .medium: return "gauge.with.needle"
        case .high: return "gauge.with.needle.fill"
        }
    }

    private var menuBarIconColor: Color {
        switch usageService.sessionUsageLevel {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
