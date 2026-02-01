import Foundation
import SwiftUI

// MARK: - Referral Model

struct Referral: Identifiable, Codable {
    let id: String
    var patientId: String
    var createdBy: String
    var referralType: ReferralType
    var priority: Priority
    var status: ReferralStatus
    var appointmentDateTime: Date?
    var followUpDueAt: Date?
    var notesClinicOnly: String?
    var lastStatusUpdateAt: Date
    var stormSensitive: Bool
    var linkedTransportRequestId: String?
    var createdAt: Date
    
    // Computed properties
    var isOverdue: Bool {
        guard let appointmentDate = appointmentDateTime else { return false }
        return appointmentDate < Date() && !status.isTerminal
    }
    
    var daysUntilAppointment: Int? {
        guard let appointmentDate = appointmentDateTime else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: appointmentDate).day
    }
}

// MARK: - Referral Type

enum ReferralType: String, Codable, CaseIterable {
    case cardiology = "cardiology"
    case imaging = "imaging"
    case mentalHealth = "mental_health"
    case physicalTherapy = "physical_therapy"
    case labWork = "lab_work"
    case specialist = "specialist"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .cardiology: return "Cardiology"
        case .imaging: return "Imaging"
        case .mentalHealth: return "Mental Health"
        case .physicalTherapy: return "Physical Therapy"
        case .labWork: return "Lab Work"
        case .specialist: return "Specialist"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .cardiology: return "heart.fill"
        case .imaging: return "camera.metering.spot"
        case .mentalHealth: return "brain.head.profile"
        case .physicalTherapy: return "figure.walk"
        case .labWork: return "syringe.fill"
        case .specialist: return "stethoscope"
        case .other: return "cross.case.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .cardiology: return .cardCoral
        case .imaging: return .cardBlue
        case .mentalHealth: return .cardLavender
        case .physicalTherapy: return .cardMint
        case .labWork: return .cardYellow
        case .specialist: return .cardSage
        case .other: return .textLight
        }
    }
}

// MARK: - Priority

enum Priority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "med"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .priorityLow
        case .medium: return .priorityMedium
        case .high: return .priorityHigh
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

// MARK: - Referral Status

enum ReferralStatus: String, Codable, CaseIterable {
    case created = "created"
    case scheduled = "scheduled"
    case reminded = "reminded"
    case attended = "attended"
    case missed = "missed"
    case needsReschedule = "needs_reschedule"
    case escalated = "escalated"
    case closed = "closed"
    case stormAtRisk = "storm_at_risk"
    
    var displayName: String {
        switch self {
        case .created: return "Created"
        case .scheduled: return "Scheduled"
        case .reminded: return "Reminded"
        case .attended: return "Attended"
        case .missed: return "Missed"
        case .needsReschedule: return "Needs Reschedule"
        case .escalated: return "Escalated"
        case .closed: return "Closed"
        case .stormAtRisk: return "Storm At Risk"
        }
    }
    
    var color: Color {
        switch self {
        case .created: return .textLight
        case .scheduled: return .cardBlue
        case .reminded: return .cardYellow
        case .attended: return .statusOk
        case .missed: return .statusMissed
        case .needsReschedule: return .statusWarning
        case .escalated: return .statusUrgent
        case .closed: return .statusOk
        case .stormAtRisk: return .stormActive
        }
    }
    
    var icon: String {
        switch self {
        case .created: return "plus.circle.fill"
        case .scheduled: return "calendar.badge.clock"
        case .reminded: return "bell.fill"
        case .attended: return "checkmark.circle.fill"
        case .missed: return "xmark.circle.fill"
        case .needsReschedule: return "arrow.triangle.2.circlepath"
        case .escalated: return "exclamationmark.triangle.fill"
        case .closed: return "checkmark.seal.fill"
        case .stormAtRisk: return "cloud.bolt.fill"
        }
    }
    
    var isTerminal: Bool {
        switch self {
        case .attended, .closed, .escalated:
            return true
        default:
            return false
        }
    }
    
    // Timeline order for progress visualization
    var progressValue: Double {
        switch self {
        case .created: return 0.2
        case .scheduled: return 0.4
        case .reminded: return 0.6
        case .attended: return 1.0
        case .closed: return 1.0
        case .missed: return 0.7
        case .needsReschedule: return 0.5
        case .escalated: return 0.8
        case .stormAtRisk: return 0.5
        }
    }
}
