import SwiftUI

// MARK: - Unassigned Rides View
// Shows all transport requests that need a driver assigned

struct UnassignedRidesView: View {
    @ObservedObject var dataService = MockDataService.shared
    @Environment(\.dismiss) private var dismiss
    
    var unassignedRequests: [TransportRequest] {
        dataService.requests.filter { $0.status == .open && $0.assignedVolunteerId == nil }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.stormBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header stats
                        statsHeader
                        
                        // Rides list
                        if unassignedRequests.isEmpty {
                            emptyState
                        } else {
                            ridesListView
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Unassigned Rides")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cardMint)
                }
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("\(unassignedRequests.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.cardBlue)
                Text("Waiting")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBlue.opacity(0.1))
            )
            
            VStack(spacing: 4) {
                Text("\(todayCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.statusWarning)
                Text("Today")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.statusWarning.opacity(0.1))
            )
            
            VStack(spacing: 4) {
                Text("\(stormSensitiveCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.stormActive)
                Text("Storm ⚠️")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.stormActive.opacity(0.1))
            )
        }
    }
    
    private var todayCount: Int {
        unassignedRequests.filter { $0.isToday }.count
    }
    
    private var stormSensitiveCount: Int {
        unassignedRequests.filter { request in
            if let referralId = request.linkedReferralId,
               let referral = dataService.referrals.first(where: { $0.id == referralId }) {
                return referral.stormSensitive
            }
            return false
        }.count
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.statusOk)
            
            Text("All Rides Assigned!")
                .font(.stormTitle3)
                .foregroundColor(.textPrimary)
            
            Text("No transport requests are waiting for drivers")
                .font(.stormBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Rides List
    
    private var ridesListView: some View {
        VStack(spacing: 12) {
            ForEach(unassignedRequests.sorted { 
                $0.timeWindowStart < $1.timeWindowStart 
            }) { request in
                UnassignedRideCard(request: request)
            }
        }
    }
}

// MARK: - Unassigned Ride Card

struct UnassignedRideCard: View {
    let request: TransportRequest
    @ObservedObject var dataService = MockDataService.shared
    @State private var isAssigning = false
    
    var patient: User? {
        dataService.users.first { $0.id == request.patientId }
    }
    
    var linkedReferral: Referral? {
        if let referralId = request.linkedReferralId {
            return dataService.referrals.first { $0.id == referralId }
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                // Patient name
                VStack(alignment: .leading, spacing: 2) {
                    Text(patient?.fullName ?? "Unknown Patient")
                        .font(.stormBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Text(request.type.displayName)
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Type badge
                HStack(spacing: 4) {
                    Image(systemName: request.type.icon)
                        .font(.system(size: 10))
                    Text(request.type.shortName)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(request.type.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(request.type.color.opacity(0.1))
                )
            }
            
            // Trip details
            VStack(alignment: .leading, spacing: 8) {
                // Pickup
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.statusOk)
                        .frame(width: 8, height: 8)
                    Text(request.pickupLocation)
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
                
                // Vertical line connector
                Rectangle()
                    .fill(Color.textLight.opacity(0.3))
                    .frame(width: 2, height: 12)
                    .padding(.leading, 3)
                
                // Dropoff
                HStack(spacing: 8) {
                    Circle()
                        .stroke(Color.cardBlue, lineWidth: 2)
                        .frame(width: 8, height: 8)
                    Text(request.dropoffLocation)
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
            }
            
            // Time info
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(.textLight)
                
                Text(request.timeWindowStart.formatted(date: .abbreviated, time: .shortened))
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                // Storm sensitive badge
                if linkedReferral?.stormSensitive == true {
                    HStack(spacing: 4) {
                        Image(systemName: "cloud.bolt.fill")
                            .font(.system(size: 10))
                        Text("Storm Sensitive")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.stormActive)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.stormActive.opacity(0.1))
                    )
                }
            }
            
            // Auto-assign button
            Button(action: autoAssign) {
                HStack {
                    if isAssigning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.badge.plus")
                    }
                    Text(isAssigning ? "Finding Driver..." : "Auto-Assign Driver")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.cardMint)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
                .cornerRadius(10)
            }
            .disabled(isAssigning)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func autoAssign() {
        isAssigning = true
        
        // Simulate auto-assignment
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Find an available volunteer
            if let volunteer = dataService.volunteers.first(where: { $0.availability == .available }) {
                dataService.assignRequest(id: request.id, volunteerId: volunteer.id)
            }
            isAssigning = false
        }
    }
}

#Preview {
    UnassignedRidesView()
}
