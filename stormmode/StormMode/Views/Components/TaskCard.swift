import SwiftUI

// MARK: - Task Card Component

struct TaskCard: View {
    let task: StormTask
    var patientName: String? = nil
    var onComplete: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(task.type.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: task.type.icon)
                        .font(.title3)
                        .foregroundColor(task.type.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.type.displayName)
                        .font(.stormHeadline)
                        .foregroundColor(.textPrimary)
                    
                    if let name = patientName {
                        Text(name)
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        // Due date
                        HStack(spacing: 4) {
                            Image(systemName: task.isOverdue ? "exclamationmark.circle.fill" : "clock")
                                .font(.caption2)
                            Text(task.dueDateFormatted)
                                .font(.stormFootnote)
                        }
                        .foregroundColor(task.isOverdue ? .statusMissed : .textLight)
                        
                        // Priority
                        Text(task.priority.displayName)
                            .font(.stormFootnote)
                            .fontWeight(.medium)
                            .foregroundColor(task.priority.color)
                    }
                }
                
                Spacer()
                
                // Complete button
                if task.status == .open, onComplete != nil {
                    Button(action: { onComplete?() }) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.statusOk)
                    }
                } else if task.status == .done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.statusOk)
                }
            }
            .padding(16)
            .background(
                task.isOverdue ? Color.statusMissed.opacity(0.1) : Color.white
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(task.isOverdue ? Color.statusMissed.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .cardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compact Task Row

struct TaskRow: View {
    let task: StormTask
    var onComplete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.type.icon)
                .font(.body)
                .foregroundColor(task.type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.type.displayName)
                    .font(.stormBody)
                    .foregroundColor(.textPrimary)
                
                Text(task.dueDateFormatted)
                    .font(.stormCaption)
                    .foregroundColor(task.isOverdue ? .statusMissed : .textLight)
            }
            
            Spacer()
            
            if task.status == .open {
                Button(action: { onComplete?() }) {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundColor(.textLight)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.statusOk)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 16) {
        TaskCard(
            task: StormTask(
                id: "1",
                type: .callPatient,
                patientId: "p1",
                linkedReferralId: nil,
                linkedRequestId: nil,
                status: .open,
                priority: .high,
                assignedTo: "s1",
                createdAt: Date(),
                dueAt: Date().addingTimeInterval(3600),
                completedAt: nil,
                notes: nil
            ),
            patientName: "Mary Thompson"
        )
        
        TaskCard(
            task: StormTask(
                id: "2",
                type: .stormCheckIn,
                patientId: "p2",
                linkedReferralId: nil,
                linkedRequestId: nil,
                status: .open,
                priority: .high,
                assignedTo: "s1",
                createdAt: Date(),
                dueAt: Date().addingTimeInterval(-3600), // Overdue
                completedAt: nil,
                notes: nil
            ),
            patientName: "Robert Chen"
        )
    }
    .padding()
    .background(Color.stormBackground)
}
