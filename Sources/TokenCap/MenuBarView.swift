import SwiftUI

// MARK: - Brand Colors

extension Color {
    static let brand = Color(red: 0.851, green: 0.482, blue: 0.247) // #D97B3F
    static let brandBg = Color(red: 1.0, green: 0.973, blue: 0.953) // #FFF8F3
    static let brandLighter = Color(red: 0.980, green: 0.745, blue: 0.678) // #FABEAD

    static let statusGreen = Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759
    static let statusYellow = Color(red: 1.0, green: 0.722, blue: 0.0) // #FFB800
    static let statusRed = Color(red: 1.0, green: 0.231, blue: 0.188) // #FF3B30

    static let greenBg = Color(red: 0.941, green: 1.0, blue: 0.957) // #F0FFF4
    static let yellowBg = Color(red: 1.0, green: 0.984, blue: 0.941) // #FFFBF0
    static let redBg = Color(red: 1.0, green: 0.953, blue: 0.941) // #FFF3F0

    static let surfaceBg = Color(red: 0.961, green: 0.961, blue: 0.969) // #F5F5F7
    static let borderLine = Color(red: 0.898, green: 0.898, blue: 0.918) // #E5E5EA

    static func statusColor(for level: UsageLevel) -> Color {
        switch level {
        case .low: return .statusGreen
        case .medium: return .statusYellow
        case .high: return .statusRed
        }
    }

    static func statusBg(for level: UsageLevel) -> Color {
        switch level {
        case .low: return .greenBg
        case .medium: return .yellowBg
        case .high: return .redBg
        }
    }
}

// MARK: - Tab

enum MenuTab: String, CaseIterable {
    case session = "Session"
    case weekly = "Weekly"
    case settings = "Settings"
}

// MARK: - Main View

struct MenuBarView: View {
    @ObservedObject var service: UsageService
    @ObservedObject var settings: SettingsManager
    @State private var selectedTab: MenuTab = .session

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            tabBar

            switch selectedTab {
            case .session:
                sessionTab
            case .weekly:
                weeklyTab
            case .settings:
                ScrollView {
                    settingsTab
                }
                .frame(maxHeight: 360)
            }

            Divider()
            footerSection
        }
        .frame(width: 320)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 7)
                .fill(headerIconBg)
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "gauge.with.needle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brand)
                )

            Text("TokenCap")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.brand)

            Spacer()

            if service.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if service.error == nil {
                Circle()
                    .fill(Color.statusColor(for: service.sessionUsageLevel))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var headerIconBg: Color {
        if service.error != nil && service.usage == nil {
            return .redBg
        }
        return Color.statusBg(for: service.sessionUsageLevel)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(MenuTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selectedTab == tab ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedTab == tab ? Color.brand : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Session Tab

    private var sessionTab: some View {
        VStack(spacing: 0) {
            if let usage = service.usage, let fiveHour = usage.fiveHour {
                heroGauge(bucket: fiveHour)

                if let error = service.error {
                    errorCard(error)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                if let extra = usage.extraUsage, extra.isEnabled {
                    extraUsageCard(extra)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            } else if let error = service.error {
                errorGaugeSection
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                errorCard(error)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            } else {
                heroGaugePlaceholder
            }
        }
    }

    // MARK: - Weekly Tab

    private var weeklyTab: some View {
        VStack(spacing: 8) {
            if let usage = service.usage {
                if let sevenDay = usage.sevenDay {
                    gaugeRow(label: "All Models", bucket: sevenDay)
                }
                if let sonnet = usage.sevenDaySonnet {
                    gaugeRow(label: "Sonnet", bucket: sonnet)
                }
                if let opus = usage.sevenDayOpus {
                    gaugeRow(label: "Opus", bucket: opus)
                }
                if let oauth = usage.sevenDayOauthApps {
                    gaugeRow(label: "OAuth Apps", bucket: oauth)
                }
                if let cowork = usage.sevenDayCowork {
                    gaugeRow(label: "Cowork", bucket: cowork)
                }
            } else if let error = service.error {
                errorCard(error)
            } else {
                Text("Loading...")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding(16)
    }

    // MARK: - Settings Tab

    private var settingsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // General
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("GENERAL")

                VStack(spacing: 0) {
                    settingRow {
                        Text("Launch at login")
                            .font(.system(size: 13))
                    } control: {
                        Toggle("", isOn: $settings.launchAtLogin)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .tint(.brand)
                    }

                    Divider()

                    settingRow {
                        Text("Poll interval")
                            .font(.system(size: 13))
                    } control: {
                        Picker("", selection: $settings.pollInterval) {
                            Text("30s").tag(30.0)
                            Text("60s").tag(60.0)
                            Text("120s").tag(120.0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 70)
                    }
                }
            }

            // Notifications
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("NOTIFICATIONS")

                settingRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Usage alerts")
                            .font(.system(size: 13))
                        Text("Notify at thresholds")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                } control: {
                    Toggle("", isOn: $settings.notificationsEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .tint(.brand)
                }

                if settings.notificationsEnabled {
                    thresholdGrid
                }
            }

            // About
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("ABOUT")

                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.brandBg)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "gauge.with.needle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.brand)
                        )

                    Text("TokenCap")
                        .font(.system(size: 15, weight: .bold))

                    Text("Version 0.1.0")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
    }

    // MARK: - Hero Gauge

    private func heroGauge(bucket: UsageBucket) -> some View {
        let level = UsageLevel.from(bucket.utilization)
        let color = Color.statusColor(for: level)
        let fraction = min(bucket.utilization, 100) / 100

        return VStack(spacing: 8) {
            ZStack {
                // Track
                Circle()
                    .inset(by: 12)
                    .stroke(Color.borderLine, lineWidth: 8)

                // Fill arc
                Circle()
                    .inset(by: 12)
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: bucket.utilization)

                // Center text
                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(Int(bucket.utilization))")
                            .font(.system(size: 32, weight: .heavy))
                            .monospacedDigit()
                        Text("%")
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(0.6)
                    }
                    .foregroundStyle(color)
                }
            }
            .frame(width: 140, height: 140)

            Text("5-Hour Window")
                .font(.system(size: 14, weight: .semibold))

            if let remaining = bucket.resetTimeRemaining {
                if level == .high {
                    Text("Resets in \(remaining) — slow down!")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.statusRed)
                } else {
                    Text("Resets in \(remaining)")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Error Gauge

    private var errorGaugeSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .inset(by: 12)
                    .stroke(Color.borderLine, style: StrokeStyle(lineWidth: 8, dash: [4, 8]))

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("--")
                        .font(.system(size: 32, weight: .heavy))
                        .monospacedDigit()
                    Text("%")
                        .font(.system(size: 16, weight: .semibold))
                        .opacity(0.6)
                }
                .foregroundStyle(.tertiary)
            }
            .frame(width: 140, height: 140)
        }
        .padding(.top, 16)
    }

    private var heroGaugePlaceholder: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .inset(by: 12)
                    .stroke(Color.borderLine, lineWidth: 8)

                ProgressView()
            }
            .frame(width: 140, height: 140)

            Text("Loading...")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Mini Gauge Row

    private func gaugeRow(label: String, bucket: UsageBucket) -> some View {
        let level = UsageLevel.from(bucket.utilization)
        let color = Color.statusColor(for: level)
        let fraction = min(bucket.utilization, 100) / 100

        return HStack(spacing: 12) {
            // Mini gauge
            ZStack {
                Circle()
                    .inset(by: 6)
                    .stroke(Color.borderLine, lineWidth: 5)

                Circle()
                    .inset(by: 6)
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int(bucket.utilization))")
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(color)
            }
            .frame(width: 44, height: 44)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))

                if let remaining = bucket.resetTimeRemaining {
                    Text("Resets in \(remaining)")
                        .font(.system(size: 11))
                        .foregroundStyle(level == .high ? Color.statusRed : Color(red: 0.682, green: 0.682, blue: 0.698))
                }
            }

            Spacer()

            Text("\(Int(bucket.utilization))%")
                .font(.system(size: 18, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.surfaceBg, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Extra Usage Card

    private func extraUsageCard(_ extra: ExtraUsage) -> some View {
        let extraLevel: UsageLevel = extra.utilization.map { UsageLevel.from($0) } ?? .low
        let extraColor = Color.statusColor(for: extraLevel)

        let bgColor: Color = {
            switch extraLevel {
            case .low: return .brandBg
            case .medium: return .yellowBg
            case .high: return .redBg
            }
        }()

        let strokeColor: Color = {
            switch extraLevel {
            case .low: return .brandLighter
            case .medium: return Color(red: 1.0, green: 0.878, blue: 0.627) // #FFE0A0
            case .high: return Color(red: 1.0, green: 0.812, blue: 0.776) // #FFCFC6
            }
        }()

        let labelColor: Color = {
            switch extraLevel {
            case .low: return .brand
            case .medium: return .statusYellow
            case .high: return .statusRed
            }
        }()

        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.brand)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Extra Usage")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(labelColor)

                if let used = extra.usedCredits, let limit = extra.monthlyLimit {
                    Text(String(format: "$%.2f / $%d", used / 100, limit / 100))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else if let used = extra.usedCredits {
                    Text(String(format: "$%.2f used", used / 100))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let util = extra.utilization {
                Text("\(Int(util))%")
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(extraColor)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(bgColor, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(strokeColor, lineWidth: 1)
        )
    }

    // MARK: - Error Card

    private func errorCard(_ error: UsageError) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: error.isTokenIssue ? "key.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.statusRed)

                Text(error.localizedDescription)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.843, green: 0.227, blue: 0.169))
            }

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if error.isTokenIssue {
                Button {
                    openTerminalWithClaude()
                } label: {
                    Text("Open Terminal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
                .background(Color.brand, in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(14)
        .background(Color.redBg, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 1.0, green: 0.812, blue: 0.776), lineWidth: 1)
        )
    }

    // MARK: - Threshold Grid

    private var thresholdGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(SettingsManager.allThresholds, id: \.self) { threshold in
                let isActive = settings.enabledThresholds.contains(threshold)
                let level = UsageLevel.from(Double(threshold))

                Button {
                    settings.toggleThreshold(threshold)
                } label: {
                    Text("\(threshold)%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isActive ? Color.white : Color(red: 0.682, green: 0.682, blue: 0.698))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isActive ? Color.statusColor(for: level) : Color.surfaceBg)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            if service.error != nil && service.usage == nil {
                Text("Disconnected")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.statusRed)
            } else if let lastUpdated = service.lastUpdated {
                Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.surfaceBg)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Text("HY")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundStyle(.secondary)
                        )
                    Text("by Helsky Labs")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 2) {
                    if selectedTab != .settings {
                        Button {
                            Task { await service.fetchUsage() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.tertiary)
            .tracking(0.5)
    }

    private func settingRow<Label: View, Control: View>(
        @ViewBuilder label: () -> Label,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack {
            label()
            Spacer()
            control()
        }
        .padding(.vertical, 8)
    }

    private func openTerminalWithClaude() {
        let script = """
        tell application "Terminal"
            activate
            do script "claude"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
