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
    var timeWindowStart: Date
    var timeWindowEnd: Date
    var mobilityNeeds: String?
    var status: TransportStatus
    var assignedVolunteerId: String?
    var linkedReferralId: String?
    var createdAt: Date
    var notes: String?
    
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
}

// MARK: - Transport Type

enum TransportType: String, Codable, CaseIterable {
    case rideToAppointment = "ride_to_appointment"
    case pharmacyPickup = "pharmacy_pickup"
    case essentialSupplyDropoff = "essential_supply_dropoff"
    
    var displayName: String {
        switch self {
        case .rideToAppointment: return "Ride to Appointment"
        case .pharmacyPickup: return "Pharmacy Pickup"
        case .essentialSupplyDropoff: return "Essential Supply Dropoff"
        }
    }
    
    var shortName: String {
        switch self {
        case .rideToAppointment: return "Ride"
        case .pharmacyPickup: return "Pharmacy"
        case .essentialSupplyDropoff: return "Supplies"
        }
    }
    
    var icon: String {
        switch self {
        case .rideToAppointment: return "car.fill"
        case .pharmacyPickup: return "cross.vial.fill"
        case .essentialSupplyDropoff: return "shippingbox.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .rideToAppointment: return .cardBlue
        case .pharmacyPickup: return .cardMint
        case .essentialSupplyDropoff: return .cardYellow
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
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .assigned: return "Assigned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .open: return .statusWarning
        case .assigned: return .cardBlue
        case .inProgress: return .cardLavender
        case .completed: return .statusOk
        case .cancelled: return .statusMissed
        }
    }
    
    var icon: String {
        switch self {
        case .open: return "clock.fill"
        case .assigned: return "person.fill.checkmark"
        case .inProgress: return "car.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}
