import SwiftUI

// MARK: - Playbook View
// "StormMode Playbook" feed showing what the system did

struct PlaybookView: View {
    @StateObject var autopilot = AutopilotService.shared
    @ObservedObject var dataService = MockDataService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Status Card
                    AutopilotStatusCard()
                    
                    // Recent Activity Header
                    HStack {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .foregroundColor(.stormActive)
                        Text("Activity Feed")
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(autopilot.playbook.count) actions")
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Playbook Feed
                    LazyVStack(spacing: 10) {
                        ForEach(autopilot.playbook) { entry in
                            PlaybookEntryRow(entry: entry)
                        }
                    }
                    
                    if autopilot.playbook.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bolt.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.textLight)
                            
                            Text("Autopilot Ready")
                                .font(.stormHeadline)
                                .foregroundColor(.textPrimary)
                            
                            Text("When Storm Mode is activated, the autopilot will:\n• Auto-create check-ins for vulnerable patients\n• Auto-assign volunteers to missions\n• Create supply delivery requests\n• Log all actions here in real-time")
                                .font(.stormCaption)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            if !dataService.stormState.isStormMode {
                                Button(action: {
                                    dataService.activateStormMode()
                                }) {
                                    HStack {
                                        Image(systemName: "cloud.bolt.fill")
                                        Text("Activate Storm Mode")
                                            .font(.stormCaptionBold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.stormActive, Color(hex: "7B4DFF")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(20)
            }
            .background(Color.stormBackground)
            .navigationTitle("Autopilot Playbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.stormCaptionBold)
                }
            }
        }
    }
}

// MARK: - Autopilot Status Card

struct AutopilotStatusCard: View {
    @StateObject var autopilot = AutopilotService.shared
    @ObservedObject var dataService = MockDataService.shared
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.title2)
                        .foregroundColor(autopilot.isAutopilotEnabled ? .stormActive : .textLight)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Autopilot")
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        Text(autopilot.isAutopilotEnabled ? "Active" : "Paused")
                            .font(.stormCaption)
                            .foregroundColor(autopilot.isAutopilotEnabled ? .statusOk : .textSecondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $autopilot.isAutopilotEnabled)
                    .labelsHidden()
                    .tint(.stormActive)
            }
            
            Divider()
            
            // Stats Row
            HStack(spacing: 0) {
                AutopilotStatPill(
                    value: autopilot.recentActionCount,
                    label: "Last 10min",
                    icon: "clock.fill",
                    color: .cardBlue
                )
                
                AutopilotStatPill(
                    value: autopilot.escalationQueue.filter { $0.level.rawValue >= 1 }.count,
                    label: "Escalated",
                    icon: "arrow.up.circle.fill",
                    color: .cardYellow
                )
                
                AutopilotStatPill(
                    value: autopilot.criticalAlerts.count,
                    label: "Critical",
                    icon: "exclamationmark.octagon.fill",
                    color: .cardCoral
                )
            }
            
            // Storm Mode Indicator
            if dataService.stormState.isStormMode {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.bolt.fill")
                        .foregroundColor(.white)
                    Text("Storm Mode Active")
                        .font(.stormCaptionBold)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Enhanced automation enabled")
                        .font(.stormFootnote)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(12)
                .background(
                    LinearGradient(
                        colors: [Color.stormActive, Color(hex: "7B4DFF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: "F8F9FC")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.stormActive.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.stormActive.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct AutopilotStatPill: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(value)")
                    .font(.stormTitle3)
            }
            .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Playbook Entry Row

struct PlaybookEntryRow: View {
    let entry: AutopilotService.PlaybookEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(entry.priority.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: entry.action.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(entry.priority.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.action.displayName)
                        .font(.stormCaptionBold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text(entry.timeAgo)
                        .font(.system(size: 10))
                        .foregroundColor(.textLight)
                }
                
                Text(entry.description)
                    .font(.stormFootnote)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                
                // Priority badge for critical/warning
                if entry.priority == .critical || entry.priority == .warning {
                    HStack(spacing: 4) {
                        Image(systemName: entry.priority.icon)
                            .font(.system(size: 9))
                        Text(entry.priority.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(entry.priority.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(entry.priority.color.opacity(0.15))
                    .cornerRadius(4)
                }
            }
        }
        .padding(12)
        .background(
            entry.priority == .critical
                ? LinearGradient(colors: [Color(hex: "FFF5F5"), Color(hex: "FFEFEF")], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color.white, Color(hex: "FAFBFC")], startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    entry.priority == .critical ? Color.cardCoral.opacity(0.3) : Color.gray.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Escalation Ladder View

struct EscalationLadderView: View {
    @StateObject var autopilot = AutopilotService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "ladder.fill")
                    .foregroundColor(.cardYellow)
                Text("Escalation Ladder")
                    .font(.stormHeadline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            
            // Ladder steps
            VStack(spacing: 0) {
                EscalationStep(
                    level: 1,
                    title: "10 min",
                    description: "Ping top 3 reliable volunteers",
                    icon: "bell.badge.fill",
                    isActive: true
                )
                
                EscalationConnector()
                
                EscalationStep(
                    level: 2,
                    title: "20 min",
                    description: "Dispatch Community Van",
                    icon: "bus.fill",
                    isActive: false
                )
                
                EscalationConnector()
                
                EscalationStep(
                    level: 3,
                    title: "30 min",
                    description: "Nurse gets red alert",
                    icon: "exclamationmark.bubble.fill",
                    isActive: false
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct EscalationStep: View {
    let level: Int
    let title: String
    let description: String
    let icon: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.cardYellow : Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(isActive ? .white : .textLight)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.stormCaptionBold)
                    .foregroundColor(isActive ? .textPrimary : .textLight)
                Text(description)
                    .font(.stormFootnote)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct EscalationConnector: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 2, height: 20)
                .padding(.leading, 15)
            Spacer()
        }
    }
}

#Preview {
    PlaybookView()
}
