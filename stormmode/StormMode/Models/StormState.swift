import Foundation

// MARK: - Storm State Model

struct StormState: Codable {
    var isStormMode: Bool
    var activatedAt: Date?
    var activatedBy: String?
    var deactivatedAt: Date?
    var rules: StormRules
    
    static let `default` = StormState(
        isStormMode: false,
        activatedAt: nil,
        activatedBy: nil,
        deactivatedAt: nil,
        rules: .default
    )
}

// MARK: - Storm Rules

struct StormRules: Codable {
    var daysLookahead: Int
    var checkInTarget: CheckInTarget
    var autoRescheduleAppointments: Bool
    var prioritizeEssentialTransport: Bool
    
    static let `default` = StormRules(
        daysLookahead: 7,
        checkInTarget: .vulnerableOnly,
        autoRescheduleAppointments: true,
        prioritizeEssentialTransport: true
    )
}

// MARK: - Check-In Target

enum CheckInTarget: String, Codable {
    case vulnerableOnly = "vulnerable_only"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .vulnerableOnly: return "Vulnerable Residents Only"
        case .all: return "All Residents"
        }
    }
}
