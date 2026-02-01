import SwiftUI

// MARK: - Patient Home View

struct PatientHomeView: View {
    @StateObject private var viewModel = PatientViewModel()
    @ObservedObject var dataService = MockDataService.shared
    @State private var showCreateRequest = false
    @State private var selectedReferral: Referral?
    
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
                    GreetingCard(name: viewModel.patientName)
                    
                    // Progress Section
                    ProgressSection(
                        progress: viewModel.overallProgress,
                        activeCount: viewModel.activeReferralsCount,
                        completedCount: viewModel.completedReferralsCount
                    )
                    
                    // Quick Actions
                    QuickActionsRow(onRequestRide: { showCreateRequest = true })
                    
                    // My Referrals
                    if !viewModel.myReferrals.isEmpty {
                        SectionHeader(title: "My Referrals", count: viewModel.myReferrals.count)
                        
                        ForEach(viewModel.myReferrals.filter { !$0.status.isTerminal }) { referral in
                            ReferralCard(referral: referral) {
                                selectedReferral = referral
                            }
                        }
                    }
                    
                    // My Requests
                    if !viewModel.myRequests.isEmpty {
                        SectionHeader(title: "My Requests", count: viewModel.pendingRequestsCount)
                        
                        ForEach(viewModel.myRequests.filter { $0.status != .completed && $0.status != .cancelled }) { request in
                            RequestCard(
                                request: request,
                                patientName: nil,
                                showPatientName: false
                            )
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
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
            .sheet(isPresented: $showCreateRequest) {
                CreateRequestView()
            }
            .sheet(item: $selectedReferral) { referral in
                ReferralDetailView(referral: referral)
            }
        }
    }
}

// MARK: - Greeting Card

struct GreetingCard: View {
    let name: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily reflection")
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 8) {
                Text("Hello, \(name)")
                    .font(.stormTitle)
                    .foregroundColor(.textPrimary)
                
                Text("👋")
                    .font(.title)
            }
            
            Text("How are you feeling today?")
                .font(.stormTitle3)
                .foregroundColor(.textPrimary)
            
            // Mood icons
            HStack(spacing: 12) {
                ForEach(["😊", "😌", "😤", "😢", "😰", "⚡️"], id: \.self) { emoji in
                    Button(action: {}) {
                        Text(emoji)
                            .font(.title)
                    }
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .cardShadow()
    }
}

// MARK: - Progress Section

struct ProgressSection: View {
    let progress: Double
    let activeCount: Int
    let completedCount: Int
    
    var percentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your progress")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                
                ProgressDisplay(
                    percentage: percentage,
                    subtitle: "Of referrals completed"
                )
            }
            
            Spacer()
            
            ProgressBubbles(progress: progress)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .cardShadow()
    }
}

// MARK: - Quick Actions Row

struct QuickActionsRow: View {
    var onRequestRide: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            QuickActionCard(
                title: "Request\nRide",
                icon: "car.fill",
                color: .cardBlue,
                action: onRequestRide
            )
            
            QuickActionCard(
                title: "Pharmacy\nPickup",
                icon: "cross.vial.fill",
                color: .cardMint,
                action: onRequestRide
            )
            
            QuickActionCard(
                title: "Get\nHelp",
                icon: "phone.fill",
                color: .cardCoral,
                action: {}
            )
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.textPrimary)
                
                Text(title)
                    .font(.stormCaptionBold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 130)
            .background(color.opacity(0.4))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var count: Int? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
            
            if let count = count {
                Text("\(count)")
                    .font(.stormCaptionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.textLight)
                    .cornerRadius(10)
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Text("See all")
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    PatientHomeView()
}
