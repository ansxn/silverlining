import SwiftUI

// MARK: - Responder List View (Staff Dashboard)

struct ResponderListView: View {
    @ObservedObject var dataService = MockDataService.shared
    @StateObject var smartMatch = SmartMatchService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingSmartMatch = true
    
    private var openRequests: [TransportRequest] {
        dataService.requests.filter { $0.status == .open }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Stats summary
                    ResponderStatsSummary(volunteers: dataService.volunteers)
                    
                    // Smart Match Section
                    if !openRequests.isEmpty {
                        SmartMatchSection(requests: openRequests)
                    }
                    
                    // All Responders Header
                    HStack {
                        Text("All Responders")
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(dataService.volunteers.count) total")
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Responder list - smart sorted
                    LazyVStack(spacing: 12) {
                        ForEach(dataService.smartMatchedVolunteers()) { volunteer in
                            ResponderCard(volunteer: volunteer)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.stormBackground)
            .navigationTitle("Responder Network")
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

// MARK: - Smart Match Section

struct SmartMatchSection: View {
    let requests: [TransportRequest]
    @StateObject var smartMatch = SmartMatchService.shared
    @ObservedObject var dataService = MockDataService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.stormActive)
                Text("Smart Match")
                    .font(.stormHeadline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(requests.count) open")
                    .font(.stormCaptionBold)
                    .foregroundColor(.stormActive)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.stormActive.opacity(0.15))
                    .cornerRadius(8)
            }
            
            ForEach(requests.prefix(3)) { request in
                SmartMatchCard(request: request)
            }
            
            if requests.count > 3 {
                Text("+\(requests.count - 3) more open requests")
                    .font(.stormFootnote)
                    .foregroundColor(.textLight)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "F8F4FF"), Color(hex: "F0EBFF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.stormActive.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SmartMatchCard: View {
    let request: TransportRequest
    let smartMatch = SmartMatchService.shared
    @ObservedObject var dataService = MockDataService.shared
    @State private var isAssigning = false
    @State private var wasAssigned = false
    @State private var matchResult: SmartMatchService.MatchResult?
    
    var body: some View {
        VStack(spacing: 10) {
            // Request info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: request.type.icon)
                            .foregroundColor(request.type.color)
                        Text(request.type.shortName)
                            .font(.stormCaptionBold)
                            .foregroundColor(.textPrimary)
                    }
                    
                    Text("\(request.pickupZone) → \(request.dropoffZone)")
                        .font(.stormFootnote)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Time window
                Text(request.timeWindowFormatted)
                    .font(.stormFootnote)
                    .foregroundColor(.textLight)
            }
            
            Divider()
            
            // Best match suggestion
            if let result = matchResult, let volunteer = result.bestMatch {
                HStack(spacing: 10) {
                    // Volunteer avatar
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.cardBlue.opacity(0.15))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Text(volunteer.initials)
                                    .font(.stormCaption)
                                    .foregroundColor(.cardBlue)
                            )
                        
                        Circle()
                            .fill(Color.statusOk)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .offset(x: 2, y: 2)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(volunteer.fullName)
                            .font(.stormCaptionBold)
                            .foregroundColor(.textPrimary)
                        
                        Text(result.reason)
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Match score
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(result.matchScore)%")
                            .font(.stormCaptionBold)
                            .foregroundColor(result.hasPerfectMatch ? .statusOk : result.hasGoodMatch ? .cardYellow : .textSecondary)
                        
                        Text("match")
                            .font(.system(size: 9))
                            .foregroundColor(.textLight)
                    }
                    
                    // Auto-assign button
                    Button(action: {
                        isAssigning = true
                        _ = smartMatch.autoAssign(request: request)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isAssigning = false
                            wasAssigned = true
                        }
                    }) {
                        if wasAssigned {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.statusOk)
                        } else if isAssigning {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text("Assign")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.statusOk)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(wasAssigned || isAssigning)
                }
            } else if matchResult != nil {
                Text("No available volunteers match this request")
                    .font(.stormFootnote)
                    .foregroundColor(.textLight)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .onAppear {
            matchResult = smartMatch.findBestMatch(for: request)
        }
    }
}

// MARK: - Stats Summary

struct ResponderStatsSummary: View {
    let volunteers: [Volunteer]
    
    private var availableCount: Int {
        volunteers.filter { $0.availability == .available }.count
    }
    
    private var onMissionCount: Int {
        volunteers.filter { $0.availability == .onMission }.count
    }
    
    private var trustedCount: Int {
        volunteers.filter { $0.tier == .trustedResponder }.count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ResponderStatPill(
                value: availableCount,
                label: "Available",
                color: .statusOk
            )
            
            ResponderStatPill(
                value: onMissionCount,
                label: "On Mission",
                color: .stormActive
            )
            
            ResponderStatPill(
                value: trustedCount,
                label: "Trusted",
                color: .cardYellow
            )
        }
    }
}

struct ResponderStatPill: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.stormTitle3)
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Responder Card

struct ResponderCard: View {
    let volunteer: Volunteer
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar with status indicator
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.cardBlue.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(volunteer.initials)
                            .font(.stormHeadline)
                            .foregroundColor(.cardBlue)
                    )
                
                // Status dot
                Circle()
                    .fill(volunteer.availability.color)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(volunteer.fullName)
                        .font(.stormHeadline)
                        .foregroundColor(.textPrimary)
                    
                    // Tier badge
                    Text(volunteer.tier.badge)
                        .font(.caption)
                    
                    if volunteer.tier == .trustedResponder {
                        Text("TRUSTED")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.cardYellow)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 12) {
                    // Zone
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                        Text(volunteer.zone)
                    }
                    .font(.stormFootnote)
                    .foregroundColor(.textSecondary)
                    
                    // Reliability
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.cardYellow)
                        Text("\(volunteer.reliabilityPercent)%")
                    }
                    .font(.stormFootnote)
                    .foregroundColor(.textSecondary)
                    
                    // Completed
                    Text("\(volunteer.completedMissions) trips")
                        .font(.stormFootnote)
                        .foregroundColor(.textLight)
                }
            }
            
            Spacer()
            
            // Status/Action
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: volunteer.availability.icon)
                        .font(.caption)
                    Text(volunteer.availability.displayName)
                        .font(.stormCaptionBold)
                }
                .foregroundColor(volunteer.availability.color)
                
                if volunteer.availability == .available {
                    Button(action: {}) {
                        Text("Assign")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.statusOk)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: "FAFBFC")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(volunteer.availability == .available ? Color.statusOk.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    ResponderListView()
}
