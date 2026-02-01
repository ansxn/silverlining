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
                    
                    // My Driver / Preferred Responder
                    MyDriverCard()
                    
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
    @State private var selectedMood: String? = nil
    @State private var showThankYou = false
    
    private let moods: [(emoji: String, label: String, message: String)] = [
        ("😊", "Happy", "Wonderful! Keep spreading that positive energy! 🌟"),
        ("😌", "Relaxed", "That's great! A calm mind helps healing. 🧘"),
        ("😤", "Frustrated", "We hear you. Take a deep breath—we're here to help. 💪"),
        ("😢", "Sad", "It's okay to feel this way. You're not alone. 💙"),
        ("😰", "Anxious", "We understand. Let us know if you need extra support. 🤝"),
        ("⚡️", "Energized", "Amazing! Channel that energy into your recovery! ⭐️")
    ]
    
    private var selectedMoodData: (emoji: String, label: String, message: String)? {
        moods.first { $0.emoji == selectedMood }
    }
    
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
            
            // Mood picker with selection
            HStack(spacing: 10) {
                ForEach(moods, id: \.emoji) { mood in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedMood = mood.emoji
                            showThankYou = true
                        }
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }) {
                        Text(mood.emoji)
                            .font(.system(size: selectedMood == mood.emoji ? 32 : 28))
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(selectedMood == mood.emoji ? Color.cardCoral.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(selectedMood == mood.emoji ? Color.cardCoral : Color.clear, lineWidth: 2)
                            )
                            .scaleEffect(selectedMood == mood.emoji ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
            
            // Supportive message when mood selected
            if showThankYou, let moodData = selectedMoodData {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Feeling \(moodData.label.lowercased())")
                            .font(.stormCaptionBold)
                            .foregroundColor(.textPrimary)
                        
                        Text("• logged")
                            .font(.stormCaption)
                            .foregroundColor(.statusOk)
                    }
                    
                    Text(moodData.message)
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.6))
                .cornerRadius(12)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFF9F5"), Color(hex: "FFEFE8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.cardCoral.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.cardCoral.opacity(0.1), radius: 10, x: 0, y: 4)
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
        .shadow(color: Color.cardMint.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

// MARK: - My Driver Card

struct MyDriverCard: View {
    @ObservedObject var dataService = MockDataService.shared
    @State private var showDriverPicker = false
    
    // Get actual preferred driver from data service
    private var myDriver: Volunteer? {
        dataService.getPreferredDriver(forPatient: dataService.currentUser.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("My Preferred Driver")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                Spacer()
                if myDriver != nil {
                    Button("Change") {
                        showDriverPicker = true
                    }
                    .font(.stormCaption)
                    .foregroundColor(.cardBlue)
                }
            }
            .padding(.bottom, 12)
            
            if let driver = myDriver {
                // Driver info
                HStack(spacing: 14) {
                    // Avatar with status
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.cardBlue.opacity(0.15))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Text(driver.initials)
                                    .font(.stormHeadline)
                                    .foregroundColor(.cardBlue)
                            )
                        
                        // Live status dot
                        Circle()
                            .fill(driver.availability.color)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2.5)
                            )
                            .offset(x: 2, y: 2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(driver.fullName)
                                .font(.stormHeadline)
                                .foregroundColor(.textPrimary)
                            
                            Text(driver.tier.badge)
                                .font(.caption)
                        }
                        
                        // Status row
                        HStack(spacing: 4) {
                            Image(systemName: driver.availability.icon)
                                .font(.system(size: 11))
                            Text(driver.availability.displayName)
                                .font(.stormCaption)
                        }
                        .foregroundColor(driver.availability.color)
                        
                        // Stats
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.cardYellow)
                                Text("\(driver.reliabilityPercent)% reliable")
                            }
                            
                            Text("\(driver.completedMissions) trips")
                                .foregroundColor(.textLight)
                        }
                        .font(.stormFootnote)
                        .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Contact button
                    Button(action: {}) {
                        Image(systemName: "message.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.cardBlue)
                            .clipShape(Circle())
                    }
                }
            } else {
                // No driver assigned
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title)
                        .foregroundColor(.cardBlue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No preferred driver set")
                            .font(.stormCaptionBold)
                            .foregroundColor(.textPrimary)
                        Text("Request the same driver for your rides")
                            .font(.stormFootnote)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button("Find") {
                        showDriverPicker = true
                    }
                    .font(.stormCaptionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cardBlue)
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "F4F8FF"), Color(hex: "EBF2FF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.cardBlue.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.cardBlue.opacity(0.1), radius: 10, x: 0, y: 4)
        .sheet(isPresented: $showDriverPicker) {
            DriverPickerView()
        }
    }
}

// MARK: - Driver Picker View

struct DriverPickerView: View {
    @ObservedObject var dataService = MockDataService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(dataService.smartMatchedVolunteers().filter { $0.tier == .trustedResponder }) { volunteer in
                        DriverPickerRow(volunteer: volunteer) {
                            // Save the selection
                            dataService.setPreferredDriver(
                                patientId: dataService.currentUser.id,
                                driverId: volunteer.id
                            )
                            dismiss()
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.stormBackground)
            .navigationTitle("Choose Preferred Driver")
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

struct DriverPickerRow: View {
    let volunteer: Volunteer
    var onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.cardBlue.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(volunteer.initials)
                            .font(.stormHeadline)
                            .foregroundColor(.cardBlue)
                    )
                
                Circle()
                    .fill(volunteer.availability.color)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: 2, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(volunteer.fullName)
                        .font(.stormHeadline)
                        .foregroundColor(.textPrimary)
                    Text("⭐️")
                        .font(.caption)
                }
                
                HStack(spacing: 8) {
                    Text(volunteer.availability.displayName)
                        .foregroundColor(volunteer.availability.color)
                    Text("•")
                        .foregroundColor(.textLight)
                    Text("\(volunteer.reliabilityPercent)% reliable")
                    Text("•")
                        .foregroundColor(.textLight)
                    Text("\(volunteer.completedMissions) trips")
                }
                .font(.stormFootnote)
                .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Button(action: onSelect) {
                Text("Select")
                    .font(.stormCaptionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.cardBlue)
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
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
