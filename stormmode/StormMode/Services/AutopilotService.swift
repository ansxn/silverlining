import Foundation
import SwiftUI
import Combine

// MARK: - Autopilot Service
// Hands-off automation engine that dispatches missions and escalates unaccepted requests

class AutopilotService: ObservableObject {
    static let shared = AutopilotService()
    
    @Published var playbook: [PlaybookEntry] = []
    @Published var isAutopilotEnabled = true
    @Published var escalationQueue: [EscalationItem] = []
    
    private var dataService = MockDataService.shared
    private var smartMatch = SmartMatchService.shared
    private var timer: Timer?
    
    private init() {
        // Seed with some demo entries
        seedDemoPlaybook()
        
        // Start the autopilot check timer (every 30 seconds in production, faster for demo)
        startAutopilotTimer()
    }
    
    // MARK: - Playbook Entry
    
    struct PlaybookEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let action: AutopilotAction
        let description: String
        let relatedMissionId: String?
        let relatedVolunteerId: String?
        let priority: Priority
        
        enum Priority: String {
            case info = "info"
            case success = "success"
            case warning = "warning"
            case critical = "critical"
            
            var color: Color {
                switch self {
                case .info: return .cardBlue
                case .success: return .statusOk
                case .warning: return .cardYellow
                case .critical: return .cardCoral
                }
            }
            
            var icon: String {
                switch self {
                case .info: return "info.circle.fill"
                case .success: return "checkmark.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .critical: return "exclamationmark.octagon.fill"
                }
            }
        }
        
        var timeAgo: String {
            let interval = Date().timeIntervalSince(timestamp)
            if interval < 60 {
                return "Just now"
            } else if interval < 3600 {
                let mins = Int(interval / 60)
                return "\(mins)m ago"
            } else {
                let hours = Int(interval / 3600)
                return "\(hours)h ago"
            }
        }
    }
    
    enum AutopilotAction: String {
        case missionCreated = "mission_created"
        case missionAssigned = "mission_assigned"
        case missionEscalated = "mission_escalated"
        case volunteerPinged = "volunteer_pinged"
        case communityVanDispatched = "community_van_dispatched"
        case nurseAlerted = "nurse_alerted"
        case stormModeActivated = "storm_mode_activated"
        case stormModeDeactivated = "storm_mode_deactivated"
        case checkInCreated = "checkin_created"
        case rescheduleMission = "reschedule_mission"
        case priorityStandby = "priority_standby"
        case virtualKioskConverted = "virtual_kiosk_converted"
        case smsBroadcast = "sms_broadcast"
        
        var displayName: String {
            switch self {
            case .missionCreated: return "Mission Created"
            case .missionAssigned: return "Auto-Assigned"
            case .missionEscalated: return "Escalated"
            case .volunteerPinged: return "Volunteers Pinged"
            case .communityVanDispatched: return "Community Van"
            case .nurseAlerted: return "Nurse Alert"
            case .stormModeActivated: return "Storm Mode ON"
            case .stormModeDeactivated: return "Storm Mode OFF"
            case .checkInCreated: return "Check-In Created"
            case .rescheduleMission: return "Reschedule Task"
            case .priorityStandby: return "Priority Standby"
            case .virtualKioskConverted: return "Virtual Kiosk"
            case .smsBroadcast: return "SMS Sent"
            }
        }
        
        var icon: String {
            switch self {
            case .missionCreated: return "plus.circle.fill"
            case .missionAssigned: return "person.badge.plus"
            case .missionEscalated: return "arrow.up.circle.fill"
            case .volunteerPinged: return "bell.badge.fill"
            case .communityVanDispatched: return "bus.fill"
            case .nurseAlerted: return "exclamationmark.bubble.fill"
            case .stormModeActivated: return "cloud.bolt.fill"
            case .stormModeDeactivated: return "sun.max.fill"
            case .checkInCreated: return "heart.text.square.fill"
            case .rescheduleMission: return "calendar.badge.clock"
            case .priorityStandby: return "star.circle.fill"
            case .virtualKioskConverted: return "desktopcomputer"
            case .smsBroadcast: return "message.fill"
            }
        }
    }
    
    // MARK: - Escalation Item
    
    struct EscalationItem: Identifiable {
        let id = UUID()
        let missionId: String
        var level: EscalationLevel
        var lastEscalatedAt: Date
        var pingedVolunteerIds: [String]
        
        enum EscalationLevel: Int {
            case initial = 0
            case pingTopVolunteers = 1
            case communityVan = 2
            case nurseAlert = 3
            
            var displayName: String {
                switch self {
                case .initial: return "Waiting"
                case .pingTopVolunteers: return "Top Volunteers Pinged"
                case .communityVan: return "Community Van Dispatched"
                case .nurseAlert: return "Nurse Alerted"
                }
            }
        }
    }
    
    // MARK: - Autopilot Actions
    
    func logAction(_ action: AutopilotAction, description: String, missionId: String? = nil, volunteerId: String? = nil, priority: PlaybookEntry.Priority = .info) {
        let entry = PlaybookEntry(
            timestamp: Date(),
            action: action,
            description: description,
            relatedMissionId: missionId,
            relatedVolunteerId: volunteerId,
            priority: priority
        )
        
        DispatchQueue.main.async {
            self.playbook.insert(entry, at: 0)
            
            // Keep only last 50 entries
            if self.playbook.count > 50 {
                self.playbook = Array(self.playbook.prefix(50))
            }
        }
    }
    
    // MARK: - Autopilot Rules
    
    func runAutopilotCheck() {
        guard isAutopilotEnabled else { return }
        
        // Rule 1: Auto-assign open missions using smart match
        autoAssignOpenMissions()
        
        // Rule 2: Escalate unaccepted missions
        escalateUnacceptedMissions()
        
        // Rule 3: Storm mode conversions
        if dataService.stormState.isStormMode {
            handleStormModeConversions()
        }
    }
    
    private func autoAssignOpenMissions() {
        let openMissions = dataService.requests.filter { $0.status == .open }
        
        for mission in openMissions {
            let result = smartMatch.findBestMatch(for: mission)
            
            // Only auto-assign if match score is very high (85+)
            if let volunteer = result.bestMatch, result.matchScore >= 85 {
                if let _ = smartMatch.autoAssign(request: mission) {
                    logAction(
                        .missionAssigned,
                        description: "Auto-assigned \(mission.type.shortName) to \(volunteer.fullName) (\(result.matchScore)% match)",
                        missionId: mission.id,
                        volunteerId: volunteer.id,
                        priority: .success
                    )
                }
            }
        }
    }
    
    private func escalateUnacceptedMissions() {
        let openMissions = dataService.requests.filter { $0.status == .open }
        let now = Date()
        
        for mission in openMissions {
            // Check how long it's been open
            let minutesOpen = now.timeIntervalSince(mission.createdAt) / 60
            
            // Find or create escalation item
            if let index = escalationQueue.firstIndex(where: { $0.missionId == mission.id }) {
                var item = escalationQueue[index]
                
                // Escalation ladder
                if minutesOpen > 30 && item.level == .initial {
                    // Ping top 3 volunteers
                    let topVolunteers = smartMatch.findBestMatch(for: mission).rankedVolunteers.prefix(3)
                    item.level = .pingTopVolunteers
                    item.pingedVolunteerIds = topVolunteers.map { $0.id }
                    item.lastEscalatedAt = now
                    escalationQueue[index] = item
                    
                    let names = topVolunteers.map { $0.volunteer.firstName }.joined(separator: ", ")
                    logAction(
                        .volunteerPinged,
                        description: "Pinged top volunteers (\(names)) for \(mission.type.shortName)",
                        missionId: mission.id,
                        priority: .warning
                    )
                    
                } else if minutesOpen > 45 && item.level == .pingTopVolunteers {
                    // Dispatch to community van
                    item.level = .communityVan
                    item.lastEscalatedAt = now
                    escalationQueue[index] = item
                    
                    logAction(
                        .communityVanDispatched,
                        description: "Community Van dispatched for \(mission.type.shortName) - no volunteer accepted",
                        missionId: mission.id,
                        priority: .warning
                    )
                    
                } else if minutesOpen > 60 && item.level == .communityVan {
                    // Nurse alert
                    item.level = .nurseAlert
                    item.lastEscalatedAt = now
                    escalationQueue[index] = item
                    
                    logAction(
                        .nurseAlerted,
                        description: "🚨 NURSE ALERT: \(mission.type.shortName) needs manual plan!",
                        missionId: mission.id,
                        priority: .critical
                    )
                }
            } else {
                // Add to escalation queue
                escalationQueue.append(EscalationItem(
                    missionId: mission.id,
                    level: .initial,
                    lastEscalatedAt: mission.createdAt,
                    pingedVolunteerIds: []
                ))
            }
        }
    }
    
    private func handleStormModeConversions() {
        // Convert upcoming ride-to-hospital to virtual kiosk options
        let upcomingRides = dataService.requests.filter {
            $0.type == .rideToAppointment &&
            $0.status == .open &&
            $0.timeWindowStart.timeIntervalSinceNow < 86400 * 2 // Within 2 days
        }
        
        for ride in upcomingRides {
            // Log conversion suggestion (in real app would modify the request)
            logAction(
                .virtualKioskConverted,
                description: "Suggested virtual kiosk + local assist for \(ride.safePatientDisplay)'s appointment",
                missionId: ride.id,
                priority: .info
            )
        }
    }
    
    // MARK: - Manual Triggers
    
    func createCheckInMission(forPatient patientId: String, reason: String) {
        logAction(
            .checkInCreated,
            description: "Created check-in mission: \(reason)",
            priority: .info
        )
    }
    
    func createRescheduleMission(forReferral referralId: String) {
        logAction(
            .rescheduleMission,
            description: "Created reschedule task for missed appointment",
            priority: .warning
        )
    }
    
    func createPriorityStandby(forReferral referralId: String) {
        logAction(
            .priorityStandby,
            description: "High-risk referral not booked by day 7 → Priority ride standby created",
            priority: .warning
        )
    }
    
    // MARK: - Timer
    
    private func startAutopilotTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.runAutopilotCheck()
        }
    }
    
    func stopAutopilotTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Demo Data
    
    private func seedDemoPlaybook() {
        // Start empty - Storm Mode activation will populate real entries
        playbook = []
    }
    
    func clearPlaybook() {
        playbook = []
        escalationQueue = []
    }
    
    // MARK: - Stats
    
    var recentActionCount: Int {
        let tenMinutesAgo = Date().addingTimeInterval(-600)
        return playbook.filter { $0.timestamp > tenMinutesAgo }.count
    }
    
    var criticalAlerts: [PlaybookEntry] {
        playbook.filter { $0.priority == .critical }
    }
}
