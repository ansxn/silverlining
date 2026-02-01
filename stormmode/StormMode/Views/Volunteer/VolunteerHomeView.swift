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
                        
                        // Greeting Card
                        VolunteerGreetingCard(name: viewModel.volunteerName)
                        
                        // Impact Stats Card
                        VolunteerImpactCard(
                            completedCount: viewModel.completedCount,
                            assignedCount: viewModel.assignedCount
                        )
                        
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
                                        onCancel: { viewModel.cancelAssignment(request.id) }
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
        .background(Color.white)
        .cornerRadius(24)
        .cardShadow()
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
        .background(Color.white)
        .cornerRadius(24)
        .cardShadow()
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
                    Text(patientName)
                        .font(.stormHeadline)
                        .foregroundColor(.textPrimary)
                    
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: request.status == .inProgress ? Color.stormActive.opacity(0.2) : Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(request.status == .inProgress ? Color.stormActive.opacity(0.3) : Color.clear, lineWidth: 2)
        )
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
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Type icon
                ZStack {
                    Circle()
                        .fill(request.type.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: request.type.icon)
                        .font(.title3)
                        .foregroundColor(request.type.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(patientName)
                        .font(.stormHeadline)
                        .foregroundColor(.textPrimary)
                    
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
                        .background(Color.statusOk)
                        .cornerRadius(10)
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .cardShadow()
        }
        .buttonStyle(PlainButtonStyle())
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
