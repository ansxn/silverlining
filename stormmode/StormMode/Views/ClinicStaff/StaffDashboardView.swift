import SwiftUI

// MARK: - Staff Dashboard View

struct StaffDashboardView: View {
    @StateObject private var viewModel = ClinicStaffViewModel()
    @ObservedObject var dataService = MockDataService.shared
    @State private var showCreateReferral = false
    @State private var showTasksList = false
    @State private var selectedReferral: Referral?
    
    var body: some View {
        NavigationStack {
            ZStack {
                WeatherBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        WeatherStatusBar()
                            .padding(.top, 8)
                        
                        if viewModel.isStormMode {
                            StormBanner(isActive: true)
                        }
                        
                        // Greeting Card
                        StaffGreetingCard(
                            name: viewModel.staffName,
                            isStormMode: viewModel.isStormMode,
                            onToggleStorm: { viewModel.toggleStormMode() }
                        )
                        
                        // AI Storm Threat Card
                        StaffStormThreatCard()
                        
                        // AI Smart Task Entry
                        StaffSmartTaskEntry()
                        
                        // AI Patient Watch List
                        StaffPatientWatchListCard()
                        
                        // Progress Section
                        StaffProgressSection(
                            closureRate: viewModel.referralClosureRate,
                            activeReferrals: viewModel.totalActiveReferrals,
                            responseRate: viewModel.checkInResponseRate
                        )
                        
                        // Alert Cards Grid
                        StaffAlertGrid(
                            overdueCount: viewModel.overdueReferrals.count,
                            urgentTasksCount: viewModel.urgentTasks.count,
                            needHelpCount: viewModel.needHelpCheckIns.count,
                            unassignedCount: viewModel.unassignedRequests.count,
                            onShowTasks: { showTasksList = true }
                        )
                        
                        // Quick Actions
                        StaffQuickActions(
                            onCreateReferral: { showCreateReferral = true },
                            onShowTasks: { showTasksList = true }
                        )
                        
                        // Urgent Tasks Preview
                        if !viewModel.urgentTasks.isEmpty {
                            SectionHeader(title: "Urgent Tasks", count: viewModel.urgentTasks.count) {
                                showTasksList = true
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.urgentTasks.prefix(3)) { task in
                                    TaskCard(
                                        task: task,
                                        patientName: viewModel.patientName(for: task.patientId ?? ""),
                                        onComplete: { viewModel.completeTask(task.id) }
                                    )
                                }
                            }
                        }
                        
                        // Overdue Referrals
                        if !viewModel.overdueReferrals.isEmpty {
                            SectionHeader(title: "Overdue Referrals", count: viewModel.overdueReferrals.count)
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.overdueReferrals.prefix(3)) { referral in
                                    ReferralCard(referral: referral) {
                                        selectedReferral = referral
                                    }
                                }
                            }
                        }
                        
                        // Check-In Alerts
                        if !viewModel.needHelpCheckIns.isEmpty || !viewModel.noReplyCheckIns.isEmpty {
                            SectionHeader(
                                title: "Check-In Alerts",
                                count: viewModel.needHelpCheckIns.count + viewModel.noReplyCheckIns.count
                            )
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.needHelpCheckIns.prefix(2)) { checkIn in
                                    CheckInAlertCard(checkIn: checkIn, type: .needHelp, viewModel: viewModel)
                                }
                                
                                ForEach(viewModel.noReplyCheckIns.prefix(2)) { checkIn in
                                    CheckInAlertCard(checkIn: checkIn, type: .noReply, viewModel: viewModel)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    StormIndicator(isActive: viewModel.isStormMode)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showCreateReferral) {
                CreateReferralView()
            }
            .sheet(isPresented: $showTasksList) {
                TasksListView()
            }
            .sheet(item: $selectedReferral) { referral in
                ReferralDetailView(referral: referral)
            }
        }
    }
}

// MARK: - Staff Greeting Card

struct StaffGreetingCard: View {
    let name: String
    let isStormMode: Bool
    var onToggleStorm: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Clinic Dashboard")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Button(action: onToggleStorm) {
                    HStack(spacing: 6) {
                        Image(systemName: isStormMode ? "bolt.fill" : "bolt")
                            .foregroundColor(isStormMode ? .stormActive : .textSecondary)
                        
                        Text(isStormMode ? "Storm Active" : "Normal")
                            .font(.stormCaptionBold)
                            .foregroundColor(isStormMode ? .stormActive : .textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isStormMode ? Color.stormActive.opacity(0.15) : Color.white.opacity(0.8))
                    .cornerRadius(20)
                }
            }
            
            HStack(spacing: 8) {
                Text("Hello, \(name)")
                    .font(.stormTitle)
                    .foregroundColor(.textPrimary)
                
                Text("👨‍⚕️")
                    .font(.title)
            }
            
            Text("How is your **patient care** going?")
                .font(.stormTitle3)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .cardShadow()
    }
}

// MARK: - Staff Progress Section

struct StaffProgressSection: View {
    let closureRate: Double
    let activeReferrals: Int
    let responseRate: Double
    
    var percentage: Int {
        Int(closureRate * 100)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Referral closure rate")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                
                ProgressDisplay(
                    percentage: percentage,
                    subtitle: "Of referrals closed"
                )
            }
            
            Spacer()
            
            ProgressBubbles(progress: closureRate)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .cardShadow()
    }
}

// MARK: - Staff Alert Grid

struct StaffAlertGrid: View {
    let overdueCount: Int
    let urgentTasksCount: Int
    let needHelpCount: Int
    let unassignedCount: Int
    var onShowTasks: () -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Overdue\nReferrals",
                count: overdueCount,
                icon: "exclamationmark.circle.fill",
                color: .statusUrgent
            )
            
            MetricCard(
                title: "Urgent\nTasks",
                count: urgentTasksCount,
                icon: "bolt.circle.fill",
                color: .statusWarning,
                onTap: onShowTasks
            )
            
            MetricCard(
                title: "Need\nHelp",
                count: needHelpCount,
                icon: "hand.raised.fill",
                color: .cardCoral
            )
            
            MetricCard(
                title: "Unassigned\nRides",
                count: unassignedCount,
                icon: "car.fill",
                color: .cardBlue
            )
        }
    }
}

// MARK: - Staff Quick Actions

struct StaffQuickActions: View {
    var onCreateReferral: () -> Void
    var onShowTasks: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            QuickActionCard(
                title: "Create\nReferral",
                icon: "plus.circle.fill",
                color: .cardLavender,
                action: onCreateReferral
            )
            
            QuickActionCard(
                title: "View\nTasks",
                icon: "checklist",
                color: .cardMint,
                action: onShowTasks
            )
            
            QuickActionCard(
                title: "Patient\nLookup",
                icon: "person.crop.circle.fill",
                color: .cardYellow,
                action: {}
            )
        }
    }
}

// MARK: - Check-In Alert Card

struct CheckInAlertCard: View {
    let checkIn: CheckIn
    let type: AlertType
    let viewModel: ClinicStaffViewModel
    
    enum AlertType {
        case needHelp
        case noReply
        
        var color: Color {
            switch self {
            case .needHelp: return .statusUrgent
            case .noReply: return .statusWarning
            }
        }
        
        var icon: String {
            switch self {
            case .needHelp: return "hand.raised.fill"
            case .noReply: return "exclamationmark.bubble.fill"
            }
        }
        
        var label: String {
            switch self {
            case .needHelp: return "Needs Help"
            case .noReply: return "No Reply"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(type.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.patientName(for: checkIn.patientId))
                    .font(.stormHeadline)
                    .foregroundColor(.textPrimary)
                
                Text(type.label)
                    .font(.stormCaption)
                    .foregroundColor(type.color)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Follow Up")
                    .font(.stormCaptionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(type.color)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .cardShadow()
    }
}

// MARK: - Staff Storm Threat Card (Simplified)

struct StaffStormThreatCard: View {
    @ObservedObject var aiService = AIStormService.shared
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Threat Ring
                ThreatRingSimple(
                    score: aiService.stormThreatLevel?.overallScore ?? 0,
                    color: aiService.stormThreatLevel?.scoreColor ?? .statusOk
                )
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("🌀 Storm Threat")
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        
                        if aiService.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                        
                        // AI Badge
                        if aiService.isUsingRealAI {
                            Text("GPT-4")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cardLavender)
                                .cornerRadius(4)
                        }
                    }
                    
                    if let threat = aiService.stormThreatLevel {
                        Text(String(format: "%.1f / 10", threat.overallScore))
                            .font(.stormTitle3)
                            .foregroundColor(threat.scoreColor)
                        
                        HStack(spacing: 8) {
                            Label("\(threat.vulnerablePatientsCount) at risk", systemImage: "person.fill")
                            Label("\(threat.atRiskAppointmentsCount) impacted", systemImage: "calendar")
                        }
                        .font(.stormFootnote)
                        .foregroundColor(.textSecondary)
                    } else {
                        Text("Analyzing conditions...")
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                // Status badge
                if let threat = aiService.stormThreatLevel {
                    VStack(spacing: 4) {
                        Image(systemName: threat.recommendation.icon)
                            .font(.title3)
                            .foregroundColor(threat.recommendation.color)
                        
                        Text(threat.recommendation.displayName)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(threat.recommendation.color)
                            .multilineTextAlignment(.center)
                    }
                    .padding(8)
                    .background(threat.recommendation.color.opacity(0.12))
                    .cornerRadius(12)
                }
            }
            
            // AI Reasoning (when available)
            if aiService.isUsingRealAI, let reasoning = aiService.aiReasoning, !reasoning.isEmpty {
                Button(action: { withAnimation { showDetails.toggle() } }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.cardLavender)
                        Text(showDetails ? "Hide AI Analysis" : "View AI Analysis")
                            .font(.stormCaptionBold)
                            .foregroundColor(.cardLavender)
                        Spacer()
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.cardLavender)
                    }
                }
                .buttonStyle(.plain)
                
                if showDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(reasoning)
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                        
                        if !aiService.aiRecommendations.isEmpty {
                            Text("Recommendations:")
                                .font(.stormCaptionBold)
                                .foregroundColor(.textPrimary)
                            
                            ForEach(aiService.aiRecommendations, id: \.self) { rec in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                    Text(rec)
                                }
                                .font(.stormCaption)
                                .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.stormBackground.opacity(0.5))
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .cardShadow()
    }
}

// Simple threat ring for staff dashboard
struct ThreatRingSimple: View {
    let score: Double
    let color: Color
    
    var progress: Double {
        score / 10.0
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 0) {
                Text(String(format: "%.1f", score))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text("/ 10")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.textLight)
            }
        }
        .frame(width: 56, height: 56)
    }
}

// MARK: - Staff Smart Task Entry

struct StaffSmartTaskEntry: View {
    @ObservedObject var aiService = AIStormService.shared
    @State private var inputText = ""
    @State private var parsedTask: ParsedTask?
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("✨ AI Task Entry")
                    .font(.stormHeadline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if parsedTask != nil {
                    Button("Clear") {
                        withAnimation {
                            parsedTask = nil
                            inputText = ""
                        }
                    }
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                }
            }
            
            // Text input
            HStack {
                TextField("Type a task naturally...", text: $inputText)
                    .font(.stormBody)
                    .textFieldStyle(.plain)
                    .onSubmit { parseTask() }
                
                if !inputText.isEmpty {
                    Button(action: parseTask) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.cardLavender)
                    }
                }
            }
            .padding(14)
            .background(Color.stormBackground.opacity(0.5))
            .cornerRadius(12)
            
            // Parsed result preview
            if let parsed = parsedTask {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.statusOk)
                        Text("Task parsed!")
                            .font(.stormCaptionBold)
                            .foregroundColor(.statusOk)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(parsed.summary)
                            .font(.stormBody)
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 12) {
                            if let patient = parsed.patient {
                                Label(patient.firstName, systemImage: "person.fill")
                            }
                            Label(parsed.priority.displayName, systemImage: "flag.fill")
                                .foregroundColor(parsed.priority.color)
                        }
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: createTask) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Task")
                            }
                            .font(.stormCaptionBold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.cardLavender)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { parsedTask = nil }) {
                            Text("Cancel")
                                .font(.stormCaption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.statusOk.opacity(0.1))
                .cornerRadius(12)
            } else {
                // Hint text
                Text("Try: \"Call Mary about cardiology referral\" or \"Urgent: check on Mr. Chen\"")
                    .font(.stormFootnote)
                    .foregroundColor(.textLight)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .cardShadow()
    }
    
    private func parseTask() {
        guard !inputText.isEmpty else { return }
        withAnimation {
            parsedTask = aiService.parseNaturalLanguageTask(inputText)
        }
    }
    
    private func createTask() {
        guard let parsed = parsedTask else { return }
        let staffId = MockDataService.shared.currentUser.id
        if let task = aiService.createTaskFromParsed(parsed, assignedTo: staffId) {
            MockDataService.shared.tasks.append(task)
        }
        withAnimation {
            parsedTask = nil
            inputText = ""
            showConfirmation = true
        }
        
        // Hide confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showConfirmation = false
        }
    }
}

// MARK: - Staff Patient Watch List Card

struct StaffPatientWatchListCard: View {
    @ObservedObject var aiService = AIStormService.shared
    @State private var isExpanded = false
    
    var watchList: [PatientRiskProfile] {
        aiService.patientWatchList
    }
    
    var body: some View {
        if !watchList.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.statusWarning)
                            
                            Text("AI Watch List")
                                .font(.stormHeadline)
                                .foregroundColor(.textPrimary)
                        }
                        
                        Spacer()
                        
                        Text("\(watchList.count) patients")
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.textLight)
                    }
                }
                .buttonStyle(.plain)
                
                // Patient avatars preview
                if !isExpanded {
                    WatchListAvatars(profiles: Array(watchList.prefix(5)), overflowCount: max(0, watchList.count - 5))
                }
                
                // Expanded list
                if isExpanded {
                    VStack(spacing: 8) {
                        ForEach(watchList) { profile in
                            PatientWatchRow(profile: profile)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(24)
            .cardShadow()
        }
    }
}

// Row for patient watch list
struct PatientWatchRow: View {
    let profile: PatientRiskProfile
    @State private var showDetail = false
    
    private var patientInitial: String {
        String(profile.patient.firstName.prefix(1))
    }
    
    private var patientDisplayName: String {
        let nameParts = profile.patient.fullName.components(separatedBy: " ")
        let lastInitial = nameParts.count > 1 ? String(nameParts.last?.prefix(1) ?? "") : ""
        return "\(profile.patient.firstName) \(lastInitial)."
    }
    
    private var riskFactorsText: String {
        Array(profile.riskFactors.prefix(2)).joined(separator: " • ")
    }
    
    private var riskScoreText: String {
        String(format: "%.0f", profile.overallRiskScore)
    }
    
    private var riskColor: Color {
        profile.riskLevel.color
    }
    
    var body: some View {
        Button(action: { showDetail = true }) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(riskColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(patientInitial)
                            .font(.stormHeadline)
                            .foregroundColor(riskColor)
                    )
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(patientDisplayName)
                        .font(.stormBody)
                        .foregroundColor(.textPrimary)
                    
                    Text(riskFactorsText)
                        .font(.stormFootnote)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Risk score
                HStack(spacing: 4) {
                    Text(riskScoreText)
                        .font(.stormHeadline)
                        .foregroundColor(riskColor)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textLight)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(riskColor.opacity(0.12))
                .cornerRadius(8)
            }
            .padding(10)
            .background(Color.stormBackground.opacity(0.3))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            PatientRiskDetailSheet(profile: profile)
        }
    }
}

// MARK: - Patient Risk Detail Sheet

struct PatientRiskDetailSheet: View {
    let profile: PatientRiskProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    scoreSection
                    riskFactorsSection
                    breakdownSection
                }
                .padding(20)
            }
            .background(Color.white)
            .navigationTitle("Risk Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(profile.riskLevel.color.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(profile.patient.firstName.prefix(1)))
                        .font(.stormTitle2)
                        .foregroundColor(profile.riskLevel.color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.patient.fullName)
                    .font(.stormTitle3)
                    .foregroundColor(.textPrimary)
                
                Text(profile.riskLevel.displayName)
                    .font(.stormCaptionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(profile.riskLevel.color)
                    .cornerRadius(6)
            }
            
            Spacer()
        }
    }
    
    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overall Risk Score")
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(String(format: "%.0f", profile.overallRiskScore))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(profile.riskLevel.color)
                
                Text("/ 20")
                    .font(.stormTitle3)
                    .foregroundColor(.textSecondary)
                    .padding(.bottom, 8)
            }
            
            Text("Score combines health factors, pending appointments, and environmental conditions.")
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
        }
        .padding(16)
        .background(Color.stormBackground.opacity(0.5))
        .cornerRadius(16)
    }
    
    private var riskFactorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Factors")
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
            
            ForEach(profile.riskFactors, id: \.self) { factor in
                riskFactorRow(factor)
            }
        }
    }
    
    private func riskFactorRow(_ factor: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconForFactor(factor))
                .foregroundColor(.statusWarning)
                .frame(width: 24)
            
            Text(factor)
                .font(.stormBody)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(12)
        .background(Color.statusWarning.opacity(0.08))
        .cornerRadius(10)
    }
    
    private var breakdownSection: some View {
        // Convert Double scores (0-5 scale) to Int for display
        let healthValue = Int(profile.vulnerabilityScore)
        let complexityValue = Int(profile.medicalComplexityScore)
        let weatherValue = Int(profile.weatherSensitivity)
        let isolationValue = Int(profile.isolationLevel)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("How Score is Calculated")
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
            
            PatientScoreBreakdownRow(title: "Health Vulnerability", value: healthValue, max: 5, description: "Based on chronic conditions, age, mobility")
            
            PatientScoreBreakdownRow(title: "Medical Complexity", value: complexityValue, max: 5, description: "Multiple conditions requiring coordinated care")
            
            PatientScoreBreakdownRow(title: "Weather Sensitivity", value: weatherValue, max: 5, description: "Risk during severe weather events")
            
            PatientScoreBreakdownRow(title: "Isolation Level", value: isolationValue, max: 5, description: "Limited access to support or transportation")
        }
    }
    
    private func iconForFactor(_ factor: String) -> String {
        if factor.contains("vulnerable") || factor.contains("Vulnerable") {
            return "heart.fill"
        } else if factor.contains("storm") || factor.contains("Storm") {
            return "cloud.bolt.fill"
        } else if factor.contains("referral") || factor.contains("Referral") || factor.contains("appointment") {
            return "calendar.badge.exclamationmark"
        } else if factor.contains("task") || factor.contains("Task") {
            return "checkmark.circle.fill"
        }
        return "exclamationmark.triangle.fill"
    }
}

// Score breakdown row for patient detail
struct PatientScoreBreakdownRow: View {
    let title: String
    let value: Int
    let max: Int
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.stormBody)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("+\(value)")
                    .font(.stormHeadline)
                    .foregroundColor(value > 0 ? .statusWarning : .textLight)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.stormBackground)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(value > 0 ? Color.statusWarning : Color.textLight)
                        .frame(width: geo.size.width * CGFloat(value) / CGFloat(max), height: 6)
                }
            }
            .frame(height: 6)
            
            Text(description)
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
        }
        .padding(12)
        .background(Color.stormBackground.opacity(0.3))
        .cornerRadius(10)
    }
}

// Avatars row for watch list
struct WatchListAvatars: View {
    let profiles: [PatientRiskProfile]
    let overflowCount: Int
    
    var body: some View {
        HStack(spacing: -8) {
            ForEach(profiles) { profile in
                PatientAvatar(profile: profile)
            }
            
            if overflowCount > 0 {
                OverflowBadge(count: overflowCount)
            }
        }
    }
}

struct PatientAvatar: View {
    let profile: PatientRiskProfile
    
    var body: some View {
        ZStack {
            Circle()
                .fill(profile.riskLevel.color.opacity(0.2))
                .frame(width: 36, height: 36)
            
            Text(String(profile.patient.firstName.prefix(1)))
                .font(.stormCaptionBold)
                .foregroundColor(profile.riskLevel.color)
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

struct OverflowBadge: View {
    let count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.textLight.opacity(0.3))
                .frame(width: 36, height: 36)
            
            Text("+\(count)")
                .font(.stormFootnote)
                .foregroundColor(.textSecondary)
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

#Preview {
    StaffDashboardView()
}
