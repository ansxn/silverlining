import SwiftUI

// MARK: - Request Card Component

struct RequestCard: View {
    let request: TransportRequest
    var patientName: String? = nil
    var showPatientName: Bool = true
    var showActions: Bool = false
    var onAccept: (() -> Void)? = nil
    var onComplete: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Type icon
                    ZStack {
                        Circle()
                            .fill(request.type.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: request.type.icon)
                            .font(.title3)
                            .foregroundColor(request.type.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.type.displayName)
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        
                        if showPatientName, let name = patientName {
                            Text(name)
                                .font(.stormCaption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status
                    RequestStatusBadge(status: request.status)
                }
                
                // Locations
                VStack(alignment: .leading, spacing: 8) {
                    LocationRow(icon: "location.circle.fill", text: request.pickupLocation, color: .statusOk)
                    LocationRow(icon: "mappin.circle.fill", text: request.dropoffLocation, color: .statusUrgent)
                }
                
                // Time
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.textLight)
                    
                    Text(request.dateFormatted)
                        .font(.stormCaptionBold)
                        .foregroundColor(.textPrimary)
                    
                    Text(request.timeWindowFormatted)
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
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
                
                // Mobility needs
                if let mobility = request.mobilityNeeds {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.roll")
                            .font(.caption)
                        Text(mobility)
                            .font(.stormCaption)
                    }
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cardYellow.opacity(0.3))
                    .cornerRadius(8)
                }
                
                // Action buttons
                if showActions {
                    HStack(spacing: 12) {
                        if request.status == .open {
                            Button(action: { onAccept?() }) {
                                Text("Accept")
                                    .font(.stormCaptionBold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.statusOk)
                                    .cornerRadius(10)
                            }
                        } else if request.status == .assigned {
                            Button(action: { onComplete?() }) {
                                Text("Complete")
                                    .font(.stormCaptionBold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.statusOk)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: { onCancel?() }) {
                                Text("Cancel")
                                    .font(.stormCaptionBold)
                                    .foregroundColor(.statusUrgent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.statusUrgent.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(20)
            .cardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Row

struct LocationRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Request Status Badge

struct RequestStatusBadge: View {
    let status: TransportStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.displayName)
                .font(.stormFootnote)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color)
        .cornerRadius(10)
    }
}

#Preview {
    VStack(spacing: 16) {
        RequestCard(
            request: TransportRequest(
                id: "1",
                type: .rideToAppointment,
                patientId: "p1",
                createdBy: "s1",
                pickupLocation: "123 Pine Street",
                dropoffLocation: "Regional Hospital",
                timeWindowStart: Date().addingTimeInterval(3600),
                timeWindowEnd: Date().addingTimeInterval(10800),
                mobilityNeeds: "Walker assistance",
                status: .open,
                assignedVolunteerId: nil,
                linkedReferralId: nil,
                createdAt: Date(),
                notes: nil
            ),
            patientName: "Mary T.",
            showActions: true
        )
    }
    .padding()
    .background(Color.stormBackground)
}
