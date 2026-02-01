import Foundation
import SwiftUI

// MARK: - Task Model

struct StormTask: Identifiable, Codable {
    let id: String
    var type: TaskType
    var patientId: String?
    var linkedReferralId: String?
    var linkedRequestId: String?
    var status: TaskStatus
    var priority: Priority
    var assignedTo: String
    var createdAt: Date
    var dueAt: Date
    var completedAt: Date?
    var notes: String?
    
    // Computed properties
    var isOverdue: Bool {
        dueAt < Date() && status != .done
    }
    
    var isDueToday: Bool {
        Calendar.current.isDateInToday(dueAt)
    }
    
    var dueDateFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: dueAt, relativeTo: Date())
    }
}

// MARK: - Task Type

enum TaskType: String, Codable, CaseIterable {
    case callPatient = "call_patient"
    case rescheduleReferral = "reschedule_referral"
    case arrangeRide = "arrange_ride"
    case stormCheckIn = "storm_check_in"
    case convertToVirtual = "convert_to_virtual"
    case escalateToHospital = "escalate_to_hospital"
    case followUp = "follow_up"
    
    var displayName: String {
        switch self {
        case .callPatient: return "Call Patient"
        case .rescheduleReferral: return "Reschedule Referral"
        case .arrangeRide: return "Arrange Ride"
        case .stormCheckIn: return "Storm Check-In"
        case .convertToVirtual: return "Convert to Virtual"
        case .escalateToHospital: return "Escalate to Hospital"
        case .followUp: return "Follow Up"
        }
    }
    
    var icon: String {
        switch self {
        case .callPatient: return "phone.fill"
        case .rescheduleReferral: return "calendar.badge.clock"
        case .arrangeRide: return "car.fill"
        case .stormCheckIn: return "cloud.bolt.fill"
        case .convertToVirtual: return "video.fill"
        case .escalateToHospital: return "cross.circle.fill"
        case .followUp: return "arrow.uturn.left.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .callPatient: return .cardBlue
        case .rescheduleReferral: return .cardYellow
        case .arrangeRide: return .cardMint
        case .stormCheckIn: return .stormActive
        case .convertToVirtual: return .cardLavender
        case .escalateToHospital: return .statusUrgent
        case .followUp: return .cardSage
        }
    }
}

// MARK: - Task Status

enum TaskStatus: String, Codable {
    case open = "open"
    case inProgress = "in_progress"
    case done = "done"
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        }
    }
    
    var color: Color {
        switch self {
        case .open: return .statusWarning
        case .inProgress: return .cardBlue
        case .done: return .statusOk
        }
    }
}
