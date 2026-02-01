import Foundation
import SwiftUI

// MARK: - Transport Request Model

struct TransportRequest: Identifiable, Codable {
    let id: String
    var type: TransportType
    var patientId: String
    var createdBy: String
    var pickupLocation: String
    var dropoffLocation: String
    var pickupZone: String          // Zone for smart matching
    var dropoffZone: String         // Zone for smart matching
    var timeWindowStart: Date
    var timeWindowEnd: Date
    var mobilityNeeds: String?
    var status: TransportStatus
    var assignedVolunteerId: String?
    var linkedReferralId: String?
    var createdAt: Date
    var notes: String?
    
    // MARK: - Mission Fields (Firebase-ready)
    var visibility: MissionVisibility
    var needsClinicFollowUp: Bool
    var failReason: String?
    var completedAt: Date?
    
    // Default initializer with backward compatibility
    init(
        id: String,
        type: TransportType,
        patientId: String,
        createdBy: String,
        pickupLocation: String,
        dropoffLocation: String,
        pickupZone: String = "Downtown",
        dropoffZone: String = "Downtown",
        timeWindowStart: Date,
        timeWindowEnd: Date,
        mobilityNeeds: String? = nil,
        status: TransportStatus,
        assignedVolunteerId: String? = nil,
        linkedReferralId: String? = nil,
        createdAt: Date,
        notes: String? = nil,
        visibility: MissionVisibility = .publicVolunteers,
        needsClinicFollowUp: Bool = false,
        failReason: String? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.patientId = patientId
        self.createdBy = createdBy
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.pickupZone = pickupZone
        self.dropoffZone = dropoffZone
        self.timeWindowStart = timeWindowStart
        self.timeWindowEnd = timeWindowEnd
        self.mobilityNeeds = mobilityNeeds
        self.status = status
        self.assignedVolunteerId = assignedVolunteerId
        self.linkedReferralId = linkedReferralId
        self.createdAt = createdAt
        self.notes = notes
        self.visibility = visibility
        self.needsClinicFollowUp = needsClinicFollowUp
        self.failReason = failReason
        self.completedAt = completedAt
    }
    
    // Computed properties
    var timeWindowFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: timeWindowStart)) - \(formatter.string(from: timeWindowEnd))"
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: timeWindowStart)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(timeWindowStart)
    }
    
    var isPast: Bool {
        timeWindowEnd < Date()
    }
    
    // Safe display for volunteer privacy
    var safePatientDisplay: String {
        // Only show first name for unassigned missions
        let fullName = MockDataService.shared.patient(for: patientId)?.fullName ?? "Patient"
        return fullName.components(separatedBy: " ").first ?? "Patient"
    }
    
    var isMissionOpen: Bool {
        status == .open && visibility == .publicVolunteers
    }
}

// MARK: - Transport Type

enum TransportType: String, Codable, CaseIterable {
    case rideToAppointment = "ride_to_appointment"
    case pharmacyPickup = "pharmacy_pickup"
    case essentialSupplyDropoff = "essential_supply_dropoff"
    case stormCheckIn = "storm_checkin"
    
    var displayName: String {
        switch self {
        case .rideToAppointment: return "Ride to Appointment"
        case .pharmacyPickup: return "Pharmacy Pickup"
        case .essentialSupplyDropoff: return "Essential Supply Dropoff"
        case .stormCheckIn: return "Storm Check-In"
        }
    }
    
    var shortName: String {
        switch self {
        case .rideToAppointment: return "Ride"
        case .pharmacyPickup: return "Pharmacy"
        case .essentialSupplyDropoff: return "Supplies"
        case .stormCheckIn: return "Check-In"
        }
    }
    
    var icon: String {
        switch self {
        case .rideToAppointment: return "car.fill"
        case .pharmacyPickup: return "cross.vial.fill"
        case .essentialSupplyDropoff: return "shippingbox.fill"
        case .stormCheckIn: return "person.wave.2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .rideToAppointment: return .cardBlue
        case .pharmacyPickup: return .cardMint
        case .essentialSupplyDropoff: return .cardYellow
        case .stormCheckIn: return .cardLavender
        }
    }
}

// MARK: - Transport Status

enum TransportStatus: String, Codable, CaseIterable {
    case open = "open"
    case assigned = "assigned"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .assigned: return "Assigned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .failed: return "Failed"
        }
    }
    
    var color: Color {
        switch self {
        case .open: return .statusWarning
        case .assigned: return .cardBlue
        case .inProgress: return .cardLavender
        case .completed: return .statusOk
        case .cancelled: return .statusMissed
        case .failed: return .statusUrgent
        }
    }
    
    var icon: String {
        switch self {
        case .open: return "clock.fill"
        case .assigned: return "person.fill.checkmark"
        case .inProgress: return "car.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Mission Visibility (Firebase-ready)

enum MissionVisibility: String, Codable {
    case publicVolunteers = "public_volunteers"
    case assignedOnly = "assigned_only"
}

