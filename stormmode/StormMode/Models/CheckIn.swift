import Foundation
import SwiftUI

// MARK: - Check-In Model

struct CheckIn: Identifiable, Codable {
    let id: String
    var patientId: String
    var stormSessionId: String
    var status: CheckInStatus
    var channel: CheckInChannel
    var receivedAt: Date?
    var sentAt: Date
    var responseMessage: String?
    
    // Computed
    var responseTimeMinutes: Int? {
        guard let received = receivedAt else { return nil }
        return Calendar.current.dateComponents([.minute], from: sentAt, to: received).minute
    }
}

// MARK: - Check-In Status

enum CheckInStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case ok = "ok"
    case needHelp = "need_help"
    case noReply = "no_reply"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .ok: return "OK"
        case .needHelp: return "Needs Help"
        case .noReply: return "No Reply"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .textLight
        case .ok: return .statusOk
        case .needHelp: return .statusUrgent
        case .noReply: return .statusWarning
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .ok: return "checkmark.circle.fill"
        case .needHelp: return "exclamationmark.triangle.fill"
        case .noReply: return "questionmark.circle.fill"
        }
    }
    
    var emoji: String {
        switch self {
        case .pending: return "⏳"
        case .ok: return "✅"
        case .needHelp: return "🆘"
        case .noReply: return "❓"
        }
    }
}

// MARK: - Check-In Channel

enum CheckInChannel: String, Codable {
    case sms = "sms"
    case app = "app"
    
    var displayName: String {
        switch self {
        case .sms: return "SMS"
        case .app: return "App"
        }
    }
    
    var icon: String {
        switch self {
        case .sms: return "message.fill"
        case .app: return "iphone"
        }
    }
}
