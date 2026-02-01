import SwiftUI

// MARK: - Referrals Tracking View
// Emphasizes "closed-loop" referrals - nothing disappears, everything is tracked

struct ReferralsTrackingView: View {
    @ObservedObject var dataService = MockDataService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: ReferralFilter = .all
    @State private var selectedReferral: Referral?
    
    enum ReferralFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case needsAction = "Needs Action"
        case completed = "Completed"
    }
    
    var filteredReferrals: [Referral] {
        switch selectedFilter {
        case .all:
            return dataService.referrals.sorted { $0.createdAt > $1.createdAt }
        case .active:
            return dataService.referrals.filter { 
                [.created, .scheduled, .reminded].contains($0.status)
            }
        case .needsAction:
            return dataService.referrals.filter {
                [.missed, .needsReschedule, .escalated, .stormAtRisk].contains($0.status)
            }
        case .completed:
            return dataService.referrals.filter {
                [.attended, .closed].contains($0.status)
            }
        }
    }
    
    // Stats for the header
    var totalReferrals: Int { dataService.referrals.count }
    var activeCount: Int { dataService.referrals.filter { [.created, .scheduled, .reminded].contains($0.status) }.count }
    var needsActionCount: Int { dataService.referrals.filter { [.missed, .needsReschedule, .escalated, .stormAtRisk].contains($0.status) }.count }
    var completedCount: Int { dataService.referrals.filter { [.attended, .closed].contains($0.status) }.count }
    var closedLoopRate: Int {
        guard totalReferrals > 0 else { return 0 }
        return Int(Double(completedCount) / Double(totalReferrals) * 100)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.stormBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Closed-Loop Header Stats
                        closedLoopHeader
                        
                        // Pipeline visualization
                        pipelineVisualization
                        
                        // Filter tabs
                        filterTabs
                        
                        // Referrals list
                        referralsList
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Referral Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cardMint)
                }
            }
            .sheet(item: $selectedReferral) { referral in
                ReferralDetailSheet(referral: referral)
            }
        }
    }
    
    // MARK: - Closed-Loop Header
    
    private var closedLoopHeader: some View {
        VStack(spacing: 16) {
            // Title with emphasis
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.title2)
                            .foregroundColor(.cardMint)
                        
                        Text("Closed-Loop Tracking")
                            .font(.stormTitle2)
                            .foregroundColor(.textPrimary)
                    }
                    
                    Text("Every referral tracked from creation to completion")
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Closed-loop rate badge
                VStack(spacing: 2) {
                    Text("\(closedLoopRate)%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.statusOk)
                    Text("Closed")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.statusOk.opacity(0.1))
                )
            }
            
            // Stats row
            HStack(spacing: 12) {
                StatPill(value: "\(totalReferrals)", label: "Total", color: .cardBlue)
                StatPill(value: "\(activeCount)", label: "Active", color: .cardMint)
                StatPill(value: "\(needsActionCount)", label: "Action", color: .statusWarning)
                StatPill(value: "\(completedCount)", label: "Done", color: .statusOk)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Pipeline Visualization
    
    private var pipelineVisualization: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Referral Journey")
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
                .padding(.leading, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    PipelineStage(
                        icon: "plus.circle.fill",
                        label: "Created",
                        count: dataService.referrals.filter { $0.status == .created }.count,
                        color: .textLight,
                        isFirst: true
                    )
                    
                    PipelineArrow()
                    
                    PipelineStage(
                        icon: "calendar.badge.clock",
                        label: "Scheduled",
                        count: dataService.referrals.filter { $0.status == .scheduled }.count,
                        color: .cardBlue
                    )
                    
                    PipelineArrow()
                    
                    PipelineStage(
                        icon: "bell.fill",
                        label: "Reminded",
                        count: dataService.referrals.filter { $0.status == .reminded }.count,
                        color: .cardYellow
                    )
                    
                    PipelineArrow()
                    
                    PipelineStage(
                        icon: "checkmark.circle.fill",
                        label: "Attended",
                        count: dataService.referrals.filter { $0.status == .attended }.count,
                        color: .statusOk,
                        isLast: true
                    )
                }
                .padding(.horizontal, 4)
            }
            
            // Bottom row: exception states
            HStack(spacing: 16) {
                Spacer()
                
                ExceptionBadge(
                    icon: "xmark.circle.fill",
                    label: "Missed",
                    count: dataService.referrals.filter { $0.status == .missed }.count,
                    color: .statusMissed
                )
                
                ExceptionBadge(
                    icon: "arrow.clockwise",
                    label: "Reschedule",
                    count: dataService.referrals.filter { $0.status == .needsReschedule }.count,
                    color: .statusWarning
                )
                
                ExceptionBadge(
                    icon: "exclamationmark.triangle.fill",
                    label: "Escalated",
                    count: dataService.referrals.filter { $0.status == .escalated }.count,
                    color: .statusUrgent
                )
                
                ExceptionBadge(
                    icon: "cloud.bolt.fill",
                    label: "Storm Risk",
                    count: dataService.referrals.filter { $0.status == .stormAtRisk }.count,
                    color: .stormActive
                )
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.7))
        )
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        HStack(spacing: 8) {
            ForEach(ReferralFilter.allCases, id: \.self) { filter in
                Button(action: { selectedFilter = filter }) {
                    Text(filter.rawValue)
                        .font(.stormCaption)
                        .fontWeight(selectedFilter == filter ? .semibold : .regular)
                        .foregroundColor(selectedFilter == filter ? .white : .textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedFilter == filter ? Color.cardMint : Color.white.opacity(0.6))
                        )
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Referrals List
    
    private var referralsList: some View {
        VStack(spacing: 12) {
            if filteredReferrals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.statusOk.opacity(0.5))
                    
                    Text("No referrals in this category")
                        .font(.stormBody)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(filteredReferrals) { referral in
                    ReferralTrackingCard(referral: referral) {
                        selectedReferral = referral
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct PipelineStage: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    var isFirst: Bool = false
    var isLast: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.textSecondary)
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(width: 70)
    }
}

struct PipelineArrow: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.textLight)
            .padding(.horizontal, 2)
    }
}

struct ExceptionBadge: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

struct ReferralTrackingCard: View {
    let referral: Referral
    let onTap: () -> Void
    @ObservedObject var dataService = MockDataService.shared
    
    var patient: User? {
        dataService.users.first { $0.id == referral.patientId }
    }
    
    var daysSinceCreated: Int {
        Calendar.current.dateComponents([.day], from: referral.createdAt, to: Date()).day ?? 0
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Patient info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(patient?.fullName ?? "Unknown Patient")
                            .font(.stormBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text(referral.referralType.displayName)
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Status badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(referral.status.color)
                            .frame(width: 8, height: 8)
                        
                        Text(referral.status.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(referral.status.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(referral.status.color.opacity(0.1))
                    )
                }
                
                // Timeline bar
                ReferralTimelineBar(status: referral.status)
                
                // Bottom info
                HStack {
                    // Priority
                    HStack(spacing: 4) {
                        Circle()
                            .fill(referral.priority.color)
                            .frame(width: 6, height: 6)
                        Text(referral.priority.displayName)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(referral.priority.color)
                    
                    Spacer()
                    
                    // Days tracking
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("Day \(daysSinceCreated + 1)")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.textLight)
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.textLight)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReferralTimelineBar: View {
    let status: ReferralStatus
    
    // Define the journey stages
    let stages: [ReferralStatus] = [.created, .scheduled, .reminded, .attended]
    
    var currentStageIndex: Int {
        if let index = stages.firstIndex(of: status) {
            return index
        }
        // Exception statuses map to their approximate position
        switch status {
        case .missed, .needsReschedule: return 2
        case .escalated, .stormAtRisk: return 1
        case .closed: return 4
        default: return 0
        }
    }
    
    var isExceptionStatus: Bool {
        [.missed, .needsReschedule, .escalated, .stormAtRisk].contains(status)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                // Dot
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 8, height: 8)
                
                // Line (except after last)
                if index < 3 {
                    Rectangle()
                        .fill(lineColor(for: index))
                        .frame(height: 2)
                }
            }
        }
        .frame(height: 8)
    }
    
    func dotColor(for index: Int) -> Color {
        if isExceptionStatus && index == currentStageIndex {
            return status.color
        }
        return index <= currentStageIndex ? .statusOk : .textLight.opacity(0.3)
    }
    
    func lineColor(for index: Int) -> Color {
        if isExceptionStatus && index >= currentStageIndex - 1 {
            return status.color.opacity(0.3)
        }
        return index < currentStageIndex ? .statusOk : .textLight.opacity(0.2)
    }
}

// MARK: - Referral Detail Sheet

struct ReferralDetailSheet: View {
    let referral: Referral
    @ObservedObject var dataService = MockDataService.shared
    @Environment(\.dismiss) private var dismiss
    
    var patient: User? {
        dataService.users.first { $0.id == referral.patientId }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Patient header
                    VStack(spacing: 8) {
                        Text(patient?.fullName ?? "Unknown")
                            .font(.stormTitle2)
                            .foregroundColor(.textPrimary)
                        
                        Text(referral.referralType.displayName)
                            .font(.stormBody)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Status card
                    VStack(spacing: 12) {
                        HStack {
                            Text("Current Status")
                                .font(.stormCaption)
                                .foregroundColor(.textSecondary)
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(referral.status.color)
                                .frame(width: 12, height: 12)
                            
                            Text(referral.status.displayName)
                                .font(.stormBodyBold)
                                .foregroundColor(referral.status.color)
                            
                            Spacer()
                            
                            Text(referral.priority.displayName)
                                .font(.stormCaption)
                                .foregroundColor(referral.priority.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(referral.priority.color.opacity(0.1))
                                )
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.9))
                    )
                    
                    // Timeline
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Referral Timeline")
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            TimelineEvent(
                                icon: "plus.circle.fill",
                                title: "Referral Created",
                                date: referral.createdAt,
                                isComplete: true,
                                isFirst: true
                            )
                            
                            if referral.appointmentDateTime != nil {
                                TimelineEvent(
                                    icon: "calendar.badge.clock",
                                    title: "Appointment Scheduled",
                                    date: referral.appointmentDateTime,
                                    isComplete: [.scheduled, .reminded, .attended, .closed].contains(referral.status)
                                )
                            }
                            
                            TimelineEvent(
                                icon: referral.status == .attended ? "checkmark.circle.fill" : "circle.dashed",
                                title: referral.status == .attended ? "Attended" : "Awaiting Completion",
                                date: referral.status == .attended ? referral.lastStatusUpdateAt : nil,
                                isComplete: [.attended, .closed].contains(referral.status),
                                isLast: true
                            )
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.9))
                    )
                    
                    // Action buttons based on status
                    if [.missed, .needsReschedule].contains(referral.status) {
                        Button(action: {
                            dataService.updateReferralStatus(id: referral.id, status: .scheduled)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Reschedule Appointment")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.cardMint)
                            .foregroundColor(.white)
                            .font(.stormBodyBold)
                            .cornerRadius(12)
                        }
                    }
                    
                    if referral.status == .scheduled || referral.status == .reminded {
                        Button(action: {
                            dataService.updateReferralStatus(id: referral.id, status: .attended)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark as Attended")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.statusOk)
                            .foregroundColor(.white)
                            .font(.stormBodyBold)
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.stormBackground.ignoresSafeArea())
            .navigationTitle("Referral Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cardMint)
                }
            }
        }
    }
}

struct TimelineEvent: View {
    let icon: String
    let title: String
    let date: Date?
    let isComplete: Bool
    var isFirst: Bool = false
    var isLast: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon and line
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(isComplete ? Color.statusOk : Color.textLight.opacity(0.3))
                        .frame(width: 2, height: 12)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isComplete ? .statusOk : .textLight)
                    .frame(width: 24, height: 24)
                
                if !isLast {
                    Rectangle()
                        .fill(isComplete ? Color.statusOk : Color.textLight.opacity(0.3))
                        .frame(width: 2, height: 24)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.stormBody)
                    .foregroundColor(isComplete ? .textPrimary : .textLight)
                
                if let date = date {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.top, isFirst ? 0 : 4)
            
            Spacer()
        }
    }
}

#Preview {
    ReferralsTrackingView()
}
