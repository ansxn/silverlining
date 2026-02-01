import SwiftUI

// MARK: - Volunteer Home View

struct VolunteerHomeView: View {
    @StateObject private var viewModel = VolunteerViewModel()
    @ObservedObject var dataService = MockDataService.shared
    @State private var selectedRequest: TransportRequest?
    @State private var showAllOpenRequests = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic weather background
                WeatherBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Weather Status Bar
                        WeatherStatusBar()
                            .padding(.top, 8)
                        
                        // Storm Banner
                        if dataService.stormState.isStormMode {
                            StormBanner(isActive: true)
                        }
                        
                        // Availability Status Toggle (Uber-style)
                        AvailabilityToggleCard()
                        
                        // Greeting Card
                        VolunteerGreetingCard(name: viewModel.volunteerName)
                        
                        // Impact Stats Card
                        VolunteerImpactCard(
                            completedCount: viewModel.completedCount,
                            assignedCount: viewModel.assignedCount
                        )
                        
                        // Community Impact Widget (Mission stats)
                        CommunityImpactWidget()
                        
                        // Patients who prefer this driver
                        MyPatientsCard()
                        
                        // Urgent Requests Alert
                        if viewModel.isStormMode && viewModel.openRequestsCount > 0 {
                            UrgentNeedCard(
                                requestCount: viewModel.openRequestsCount,
                                onViewRequests: { showAllOpenRequests = true }
                            )
                        }
                        
                        // My Current Trips (Active Assignments)
                        let activeRequests = viewModel.myAssignedRequests.filter { 
                            $0.status == .assigned || $0.status == .inProgress 
                        }
                        if !activeRequests.isEmpty {
                            SectionHeader(title: "My Current Trips", count: activeRequests.count)
                            
                            VStack(spacing: 12) {
                                ForEach(activeRequests) { request in
                                    ActiveTripCard(
                                        request: request,
                                        patientName: viewModel.patientName(for: request.patientId),
                                        onStart: { viewModel.startTrip(request.id) },
                                        onComplete: { viewModel.completeTrip(request.id) },
                                        onCancel: { viewModel.cancelAssignment(request.id) },
                                        onFail: { reason in viewModel.failMission(request.id, reason: reason) }
                                    )
                                }
                            }
                        }
                        
                        // Quick Actions
                        VolunteerQuickActions(
                            openCount: viewModel.openRequestsCount,
                            onViewOpen: { showAllOpenRequests = true }
                        )
                        
                        // Available Requests Preview
                        if !viewModel.openRequests.isEmpty {
                            SectionHeader(title: "Available Requests", count: viewModel.openRequests.count) {
                                showAllOpenRequests = true
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.openRequests.prefix(3)) { request in
                                    OpenRequestCard(
                                        request: request,
                                        patientName: viewModel.patientName(for: request.patientId),
                                        onAccept: { viewModel.acceptRequest(request.id) },
                                        onTap: { selectedRequest = request }
                                    )
                                }
                                
                                if viewModel.openRequests.count > 3 {
                                    Button(action: { showAllOpenRequests = true }) {
                                        HStack {
                                            Text("View all \(viewModel.openRequests.count) requests")
                                                .font(.stormCaptionBold)
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.stormActive)
                                        .padding(.vertical, 12)
                                    }
                                }
                            }
                        } else if activeRequests.isEmpty {
                            // Empty state when nothing to do
                            VolunteerEmptyState()
                        }
                        
                        // Recent Completed Trips
                        let recentCompleted = viewModel.myAssignedRequests.filter { $0.status == .completed }.prefix(3)
                        if !recentCompleted.isEmpty {
                            SectionHeader(title: "Recent Trips")
                            
                            VStack(spacing: 12) {
                                ForEach(Array(recentCompleted)) { request in
                                    CompletedTripCard(
                                        request: request,
                                        patientName: viewModel.patientName(for: request.patientId)
                                    )
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
                    StormIndicator(isActive: dataService.stormState.isStormMode)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .sheet(item: $selectedRequest) { request in
                RequestDetailView(request: request, viewModel: viewModel)
            }
            .sheet(isPresented: $showAllOpenRequests) {
                AllOpenRequestsView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Availability Toggle Card

struct AvailabilityToggleCard: View {
    @ObservedObject var dataService = MockDataService.shared
    
    private var volunteer: Volunteer? {
        dataService.currentVolunteer
    }
    
    private var availability: VolunteerAvailability {
        volunteer?.availability ?? .unavailable
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Responder Status")
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 8) {
                        // Status indicator
                        Circle()
                            .fill(availability.color)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: availability.color.opacity(0.5), radius: 4)
                        
                        Text(availability.displayName)
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                Spacer()
                
                // Tier badge
                if let vol = volunteer {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(vol.tier.badge)
                            .font(.title2)
                        Text(vol.tier.displayName)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(vol.tier.color)
                    }
                }
            }
            
            // Toggle buttons
            if availability != .onMission {
                HStack(spacing: 12) {
                    AvailabilityButton(
                        title: "Available",
                        icon: "checkmark.circle.fill",
                        isSelected: availability == .available,
                        color: .statusOk
                    ) {
                        if availability != .available {
                            withAnimation(.spring(response: 0.3)) {
                                dataService.toggleVolunteerAvailability(volunteerId: volunteer?.id ?? "")
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                    
                    AvailabilityButton(
                        title: "Unavailable",
                        icon: "moon.fill",
                        isSelected: availability == .unavailable,
                        color: .textLight
                    ) {
                        if availability != .unavailable {
                            withAnimation(.spring(response: 0.3)) {
                                dataService.toggleVolunteerAvailability(volunteerId: volunteer?.id ?? "")
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                }
            } else {
                // On mission - show status
                HStack(spacing: 8) {
                    Image(systemName: "car.fill")
                        .foregroundColor(.stormActive)
                    Text("Currently on a mission")
                        .font(.stormCaptionBold)
                        .foregroundColor(.stormActive)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.stormActive.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Zone & reliability display
            if let vol = volunteer {
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.cardBlue)
                        Text(vol.zone)
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Divider()
                        .frame(height: 16)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.cardYellow)
                        Text("\(vol.reliabilityPercent)% reliable")
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Divider()
                        .frame(height: 16)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.statusOk)
                        Text("\(vol.completedMissions) completed")
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    availability == .available ? Color(hex: "F0FFF4") : Color(hex: "F8F9FA"),
                    availability == .available ? Color(hex: "E6F9EC") : Color(hex: "F1F3F4")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(availability.color.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: availability.color.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

struct AvailabilityButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.stormCaptionBold)
            }
            .foregroundColor(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - My Patients Card (Preferred Driver)

struct MyPatientsCard: View {
    @ObservedObject var dataService = MockDataService.shared
    
    private var myPatients: [User] {
        dataService.patientsPreferringCurrentVolunteer
    }
    
    var body: some View {
        // Only show if there's at least one patient who prefers this driver
        if !myPatients.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.cardCoral)
                    Text("Patients Who Prefer You")
                        .font(.stormCaptionBold)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("\(myPatients.count)")
                        .font(.stormHeadline)
                        .foregroundColor(.cardCoral)
                }
                
                ForEach(myPatients) { patient in
                    HStack(spacing: 12) {
                        // Avatar
                        Circle()
                            .fill(Color.cardCoral.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(patient.initials)
                                    .font(.stormCaptionBold)
                                    .foregroundColor(.cardCoral)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(patient.fullName)
                                .font(.stormCaptionBold)
                                .foregroundColor(.textPrimary)
                            
                            if let address = patient.address {
                                Text(address)
                                    .font(.stormFootnote)
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Contact button
                        Button(action: {}) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.cardCoral)
                                .clipShape(Circle())
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(12)
                }
                
                Text("These patients will see you as their preferred driver")
                    .font(.stormFootnote)
                    .foregroundColor(.textLight)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FFF5F5"), Color(hex: "FFEFEF")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cardCoral.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.cardCoral.opacity(0.1), radius: 8, x: 0, y: 3)
        }
    }
}

// MARK: - Volunteer Greeting Card

struct VolunteerGreetingCard: View {
    let name: String
    
    private var motivationalQuote: String {
        let quotes = [
            "Every ride makes a difference!",
            "You're helping someone heal today.",
            "Small acts, big impact.",
            "Thank you for volunteering!"
        ]
        return quotes.randomElement() ?? quotes[0]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Volunteer Dashboard")
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 8) {
                Text("Hello, \(name)")
                    .font(.stormTitle)
                    .foregroundColor(.textPrimary)
                
                Text("🚗")
                    .font(.title)
            }
            
            Text("Ready to make a **difference** today?")
                .font(.stormTitle3)
                .foregroundColor(.textPrimary)
            
            // Motivational quote
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundColor(.cardMint)
                
                Text(motivationalQuote)
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                    .italic()
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "F8F6FF"), Color(hex: "F0EDFF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.cardLavender.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.cardLavender.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Volunteer Impact Card

struct VolunteerImpactCard: View {
    let completedCount: Int
    let assignedCount: Int
    
    var impactLevel: String {
        switch completedCount {
        case 0: return "Getting Started"
        case 1...5: return "Making Waves"
        case 6...15: return "Community Hero"
        case 16...30: return "Super Volunteer"
        default: return "Legend"
        }
    }
    
    var impactEmoji: String {
        switch completedCount {
        case 0: return "🌱"
        case 1...5: return "🌟"
        case 6...15: return "💫"
        case 16...30: return "🏆"
        default: return "👑"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Impact")
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 8) {
                        Text(impactEmoji)
                            .font(.title)
                        Text(impactLevel)
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                Spacer()
                
                // Progress bubbles
                ProgressBubbles(progress: min(Double(completedCount) / 30.0, 1.0))
            }
            
            // Stats row
            HStack(spacing: 20) {
                ImpactStatBlock(
                    value: "\(completedCount)",
                    label: "Trips Completed",
                    icon: "checkmark.circle.fill",
                    color: .statusOk
                )
                
                ImpactStatBlock(
                    value: "\(assignedCount)",
                    label: "In Progress",
                    icon: "car.fill",
                    color: .cardBlue
                )
                
                ImpactStatBlock(
                    value: "\(completedCount * 15)mi",
                    label: "Est. Distance",
                    icon: "road.lanes",
                    color: .cardMint
                )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "F0F9F7"), Color(hex: "E8F5F1")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.cardMint.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.cardMint.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

struct ImpactStatBlock: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.stormTitle3)
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Community Impact Widget

struct CommunityImpactWidget: View {
    private var stats: CommunityImpactStats { CommunityImpactStats.current }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🏘️ Community Impact")
                    .font(.stormHeadline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("Today")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
            }
            
            HStack(spacing: 16) {
                CommunityStatPill(
                    value: stats.openMissions,
                    label: "Open",
                    icon: "clock.fill",
                    color: .statusWarning
                )
                
                CommunityStatPill(
                    value: stats.completedToday,
                    label: "Completed",
                    icon: "checkmark.circle.fill",
                    color: .statusOk
                )
                
                CommunityStatPill(
                    value: stats.stormCheckInsCompleted,
                    label: "Check-Ins",
                    icon: "person.wave.2.fill",
                    color: .cardLavender
                )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.cardMint.opacity(0.1), Color.cardBlue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.cardMint.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CommunityStatPill: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text("\(value)")
                    .font(.stormTitle3)
                    .foregroundColor(.textPrimary)
            }
            
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.6))
        .cornerRadius(12)
    }
}

// MARK: - Urgent Need Card (Storm Mode)

struct UrgentNeedCard: View {
    let requestCount: Int
    var onViewRequests: () -> Void
    
    var body: some View {
        Button(action: onViewRequests) {
            HStack(spacing: 16) {
                // Alert icon
                ZStack {
                    Circle()
                        .fill(Color.statusUrgent.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "bolt.car.fill")
                        .font(.title2)
                        .foregroundColor(.statusUrgent)
                        .symbolEffect(.pulse, options: .repeating)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("⚠️ Volunteers Needed")
                        .font(.stormHeadline)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(requestCount) patients waiting for rides")
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.textLight)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.statusUrgent.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.statusUrgent.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Active Trip Card

struct ActiveTripCard: View {
    let request: TransportRequest
    let patientName: String
    var onStart: () -> Void
    var onComplete: () -> Void
    var onCancel: () -> Void
    var onFail: ((String) -> Void)? = nil
    
    @State private var showFailSheet = false
    @State private var failReason = ""
    
    private var isStormMission: Bool {
        request.type == .stormCheckIn
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(request.type.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: request.type.icon)
                        .font(.title3)
                        .foregroundColor(request.type.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(patientName)
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        
                        // Storm badge
                        if isStormMission {
                            Text("🌀 STORM")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.stormActive)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(request.type.displayName)
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Status
                TripStatusBadge(status: request.status)
            }
            
            // Route
            VStack(alignment: .leading, spacing: 6) {
                RouteStep(
                    icon: "location.circle.fill",
                    text: request.pickupLocation,
                    color: .statusOk,
                    isActive: request.status == .assigned
                )
                
                // Dotted line
                HStack {
                    Rectangle()
                        .fill(Color.textLight)
                        .frame(width: 2, height: 20)
                        .padding(.leading, 10)
                    Spacer()
                }
                
                RouteStep(
                    icon: "mappin.circle.fill",
                    text: request.dropoffLocation,
                    color: .statusUrgent,
                    isActive: request.status == .inProgress
                )
            }
            
            // Time
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.textLight)
                
                Text(request.timeWindowFormatted)
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                
                if request.isToday {
                    Text("TODAY")
                        .font(.stormFootnote)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.statusWarning)
                        .cornerRadius(6)
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                if request.status == .assigned {
                    Button(action: onStart) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Trip")
                        }
                        .font(.stormCaptionBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.stormActive)
                        .cornerRadius(12)
                    }
                } else if request.status == .inProgress {
                    Button(action: onComplete) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Complete")
                        }
                        .font(.stormCaptionBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.statusOk)
                        .cornerRadius(12)
                    }
                }
                
                // Can't Complete button (only when in progress)
                if request.status == .inProgress && onFail != nil {
                    Button(action: { showFailSheet = true }) {
                        Text("Can't Complete")
                            .font(.stormCaptionBold)
                            .foregroundColor(.statusUrgent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(Color.statusUrgent.opacity(0.1))
                            .cornerRadius(12)
                    }
                } else {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.stormCaptionBold)
                            .foregroundColor(.statusUrgent)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.statusUrgent.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: isStormMission 
                    ? [Color(hex: "F0EDFF"), Color(hex: "EAE6FF")]
                    : [Color(hex: "FFFBF5"), Color(hex: "FFF8EE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isStormMission ? Color.stormActive.opacity(0.5) : (request.status == .inProgress ? Color.cardYellow.opacity(0.5) : Color(hex: "F5EEE0")), lineWidth: 1.5)
        )
        .shadow(color: isStormMission ? Color.stormActive.opacity(0.15) : Color.cardYellow.opacity(0.15), radius: 10, x: 0, y: 4)
        .sheet(isPresented: $showFailSheet) {
            FailMissionSheet(
                patientName: patientName,
                reason: $failReason,
                onSubmit: {
                    onFail?(failReason.isEmpty ? "Unable to complete" : failReason)
                    showFailSheet = false
                    failReason = ""
                },
                onCancel: { showFailSheet = false }
            )
            .presentationDetents([.height(300)])
        }
    }
}

// MARK: - Fail Mission Sheet

struct FailMissionSheet: View {
    let patientName: String
    @Binding var reason: String
    var onSubmit: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Can't Complete Mission")
                    .font(.stormTitle3)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.textLight)
                }
            }
            
            Text("Let the clinic know why you couldn't complete the visit for \(patientName).")
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
            
            // Reason input
            TextField("Reason (e.g., no answer, wrong address)", text: $reason)
                .font(.stormBody)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            // Quick reasons
            HStack(spacing: 8) {
                QuickReasonButton(text: "No answer", selection: $reason)
                QuickReasonButton(text: "Wrong address", selection: $reason)
                QuickReasonButton(text: "Not home", selection: $reason)
            }
            
            Spacer()
            
            // Submit
            Button(action: onSubmit) {
                Text("Report & Notify Clinic")
                    .font(.stormCaptionBold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.statusUrgent)
                    .cornerRadius(12)
            }
        }
        .padding(20)
    }
}

struct QuickReasonButton: View {
    let text: String
    @Binding var selection: String
    
    var body: some View {
        Button(action: { selection = text }) {
            Text(text)
                .font(.stormFootnote)
                .foregroundColor(selection == text ? .white : .textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selection == text ? Color.stormActive : Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

struct RouteStep: View {
    let icon: String
    let text: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
            
            Text(text)
                .font(isActive ? .stormBodyBold : .stormBody)
                .foregroundColor(isActive ? .textPrimary : .textSecondary)
                .lineLimit(1)
        }
    }
}

struct TripStatusBadge: View {
    let status: TransportStatus
    
    var displayText: String {
        switch status {
        case .assigned: return "Ready"
        case .inProgress: return "En Route"
        default: return status.displayName
        }
    }
    
    var body: some View {
        Text(displayText)
            .font(.stormCaptionBold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(status.color)
            .cornerRadius(12)
    }
}

// MARK: - Open Request Card

struct OpenRequestCard: View {
    let request: TransportRequest
    let patientName: String
    var onAccept: () -> Void
    var onTap: () -> Void
    
    @ObservedObject var dataService = MockDataService.shared
    @State private var showMatchDetails = false
    
    private var isStormMission: Bool {
        request.type == .stormCheckIn
    }
    
    // Get match score for current volunteer
    private var matchResult: SmartMatchService.MatchResult {
        SmartMatchService.shared.findBestMatch(for: request)
    }
    
    private var myMatch: SmartMatchService.ScoredVolunteer? {
        guard let volunteerId = dataService.currentVolunteer?.id else { return nil }
        return matchResult.rankedVolunteers.first { $0.volunteer.id == volunteerId }
    }
    
    private var matchScore: Int {
        myMatch?.score ?? 0
    }
    
    private var matchColor: Color {
        if matchScore >= 85 { return .statusOk }
        if matchScore >= 70 { return .cardMint }
        if matchScore >= 50 { return .statusWarning }
        return .textLight
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main content
                HStack(spacing: 12) {
                    // Type icon with match indicator
                    ZStack {
                        Circle()
                            .fill(request.type.color.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: request.type.icon)
                            .font(.title3)
                            .foregroundColor(request.type.color)
                        
                        // Match score badge (top-right of icon)
                        if matchScore > 0 {
                            Text("\(matchScore)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(matchColor))
                                .offset(x: 16, y: -16)
                        }
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(patientName)
                                .font(.stormHeadline)
                                .foregroundColor(.textPrimary)
                            
                            // Storm badge
                            if isStormMission {
                                Text("🌀 STORM")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.stormActive)
                                    .cornerRadius(4)
                            }
                            
                            // High match badge
                            if matchScore >= 85 {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 8))
                                    Text("GREAT MATCH")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                .foregroundColor(.statusOk)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.statusOk.opacity(0.15))
                                .cornerRadius(4)
                            }
                        }
                        
                        Text(request.dropoffLocation)
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(request.timeWindowFormatted)
                                .font(.stormFootnote)
                        }
                        .foregroundColor(.textLight)
                    }
                    
                    Spacer()
                    
                    // Accept button
                    Button(action: onAccept) {
                        Text("Accept")
                            .font(.stormCaptionBold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isStormMission ? Color.stormActive : Color.statusOk)
                            .cornerRadius(10)
                    }
                }
                .padding(14)
                
                // Smart Match breakdown (expandable)
                if showMatchDetails, let match = myMatch {
                    SmartMatchBreakdown(breakdown: match.breakdown)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Match score bar (tap to expand)
                if matchScore > 0 {
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showMatchDetails.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "target")
                                .font(.system(size: 11))
                            
                            Text("Your Match Score")
                                .font(.system(size: 11, weight: .medium))
                            
                            // Score bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(matchColor)
                                        .frame(width: geo.size.width * CGFloat(matchScore) / 100, height: 6)
                                }
                            }
                            .frame(height: 6)
                            
                            Text("\(matchScore)%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(matchColor)
                            
                            Image(systemName: showMatchDetails ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(.textLight)
                        }
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(
                LinearGradient(
                    colors: isStormMission 
                        ? [Color(hex: "F0EDFF"), Color(hex: "EBE7FF")]
                        : [Color(hex: "FAFAFA"), Color(hex: "F5F5F5")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        matchScore >= 85 
                            ? Color.statusOk.opacity(0.4) 
                            : (isStormMission ? Color.stormActive.opacity(0.4) : Color.gray.opacity(0.15)), 
                        lineWidth: matchScore >= 85 ? 2 : 1
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Smart Match Breakdown

struct SmartMatchBreakdown: View {
    let breakdown: SmartMatchService.ScoredVolunteer.ScoreBreakdown
    
    var body: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack(spacing: 16) {
                // Location
                MatchFactorPill(
                    icon: "location.fill",
                    label: "Location",
                    score: breakdown.zoneMatchScore,
                    maxScore: 25,
                    color: .cardBlue
                )
                
                // Availability
                MatchFactorPill(
                    icon: "clock.fill",
                    label: "Availability",
                    score: breakdown.availabilityScore,
                    maxScore: 30,
                    color: .cardMint
                )
                
                // Reliability
                MatchFactorPill(
                    icon: "star.fill",
                    label: "Reliability",
                    score: breakdown.reliabilityScore,
                    maxScore: 15,
                    color: .cardYellow
                )
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
    }
}

struct MatchFactorPill: View {
    let icon: String
    let label: String
    let score: Int
    let maxScore: Int
    let color: Color
    
    private var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(score) / Double(maxScore)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text("\(score)/\(maxScore)")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.textSecondary)
            
            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * percentage, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Completed Trip Card

struct CompletedTripCard: View {
    let request: TransportRequest
    let patientName: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.statusOk)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(patientName)
                    .font(.stormBodyBold)
                    .foregroundColor(.textPrimary)
                
                Text(request.dropoffLocation)
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(request.dateFormatted)
                .font(.stormFootnote)
                .foregroundColor(.textLight)
        }
        .padding(14)
        .background(Color.statusOk.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Volunteer Quick Actions

struct VolunteerQuickActions: View {
    let openCount: Int
    var onViewOpen: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            QuickActionCard(
                title: "View\nRequests",
                icon: "car.fill",
                color: .cardBlue,
                action: onViewOpen
            )
            .overlay(
                CountBadge(count: openCount)
                    .offset(x: 8, y: -8),
                alignment: .topTrailing
            )
            
            QuickActionCard(
                title: "My\nHistory",
                icon: "clock.arrow.circlepath",
                color: .cardMint,
                action: {}
            )
            
            QuickActionCard(
                title: "Contact\nClinic",
                icon: "phone.fill",
                color: .cardLavender,
                action: {}
            )
        }
    }
}

// MARK: - Count Badge

struct CountBadge: View {
    let count: Int
    
    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.stormCaptionBold)
                .foregroundColor(.white)
                .frame(minWidth: 24)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.statusUrgent)
                .cornerRadius(12)
        }
    }
}

// MARK: - Volunteer Empty State

struct VolunteerEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 48))
                .foregroundColor(.cardMint)
            
            Text("All Caught Up!")
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
            
            Text("No transport requests at the moment.\nCheck back soon or enjoy your break!")
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 8) {
                ForEach(["☕️", "📚", "🎧", "🌿"], id: \.self) { emoji in
                    Text(emoji)
                        .font(.title)
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.white)
        .cornerRadius(20)
        .cardShadow()
    }
}

// MARK: - Request Detail View

struct RequestDetailView: View {
    let request: TransportRequest
    @ObservedObject var viewModel: VolunteerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Request info
                    RequestCard(
                        request: request,
                        patientName: viewModel.patientName(for: request.patientId),
                        showActions: true,
                        onAccept: {
                            viewModel.acceptRequest(request.id)
                            dismiss()
                        },
                        onComplete: {
                            viewModel.completeTrip(request.id)
                            dismiss()
                        },
                        onCancel: {
                            viewModel.cancelAssignment(request.id)
                            dismiss()
                        }
                    )
                    
                    // Map placeholder
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardMint.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "map.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.cardMint)
                                Text("Map View")
                                    .font(.stormCaption)
                                    .foregroundColor(.textSecondary)
                            }
                        )
                    
                    // Notes
                    if let notes = request.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.stormHeadline)
                                .foregroundColor(.textPrimary)
                            
                            Text(notes)
                                .font(.stormBody)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.cardYellow.opacity(0.2))
                        .cornerRadius(16)
                    }
                }
                .padding(20)
            }
            .background(Color.stormBackground.ignoresSafeArea())
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - All Open Requests View

struct AllOpenRequestsView: View {
    @ObservedObject var viewModel: VolunteerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.openRequests.isEmpty {
                        VolunteerEmptyState()
                            .padding(.top, 40)
                    } else {
                        ForEach(viewModel.openRequests) { request in
                            RequestCard(
                                request: request,
                                patientName: viewModel.patientName(for: request.patientId),
                                showActions: true,
                                onAccept: {
                                    viewModel.acceptRequest(request.id)
                                }
                            )
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.stormBackground.ignoresSafeArea())
            .navigationTitle("Available Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Shared Empty State Component

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.textLight)
            
            Text(title)
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
            
            Text(message)
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .cornerRadius(20)
        .cardShadow()
    }
}

#Preview {
    VolunteerHomeView()
}
