import SwiftUI

// MARK: - Referral Card Component

struct ReferralCard: View {
    let referral: Referral
    var patientName: String? = nil
    var showPatientName: Bool = false
    var onTap: (() -> Void)? = nil
    
    private var cardColor: Color {
        referral.referralType.color
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Type icon
                    Image(systemName: referral.referralType.icon)
                        .font(.title2)
                        .foregroundColor(.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(referral.referralType.displayName)
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        
                        if showPatientName, let name = patientName {
                            Text(name)
                                .font(.stormCaption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Priority badge
                    PriorityBadge(priority: referral.priority)
                }
                
                // Status and Date
                HStack {
                    StatusPill(status: referral.status)
                    
                    Spacer()
                    
                    if let date = referral.appointmentDateTime {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(formatDate(date))
                                .font(.stormCaption)
                        }
                        .foregroundColor(.textSecondary)
                    }
                }
                
                // Progress ring (mini)
                if !referral.status.isTerminal {
                    ProgressBar(value: referral.status.progressValue, color: referral.status.color)
                }
            }
            .padding(16)
            .background(cardColor.opacity(0.3))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        Text(priority.displayName)
            .font(.stormFootnote)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color)
            .cornerRadius(8)
    }
}

// MARK: - Status Pill

struct StatusPill: View {
    let status: ReferralStatus
    
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

// MARK: - Progress Bar

struct ProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.5))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * value, height: 6)
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    VStack(spacing: 16) {
        ReferralCard(
            referral: Referral(
                id: "1",
                patientId: "p1",
                createdBy: "s1",
                referralType: .cardiology,
                priority: .high,
                status: .scheduled,
                appointmentDateTime: Date().addingTimeInterval(86400 * 3),
                followUpDueAt: nil,
                notesClinicOnly: nil,
                lastStatusUpdateAt: Date(),
                stormSensitive: true,
                linkedTransportRequestId: nil,
                createdAt: Date()
            )
        )
        
        ReferralCard(
            referral: Referral(
                id: "2",
                patientId: "p1",
                createdBy: "s1",
                referralType: .mentalHealth,
                priority: .medium,
                status: .stormAtRisk,
                appointmentDateTime: Date().addingTimeInterval(86400),
                followUpDueAt: nil,
                notesClinicOnly: nil,
                lastStatusUpdateAt: Date(),
                stormSensitive: true,
                linkedTransportRequestId: nil,
                createdAt: Date()
            ),
            patientName: "Mary T.",
            showPatientName: true
        )
    }
    .padding()
    .background(Color.stormBackground)
}
