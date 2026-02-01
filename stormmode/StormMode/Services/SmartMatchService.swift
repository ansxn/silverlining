import Foundation
import SwiftUI
import Combine

// MARK: - Smart Match Service
// Uber-grade volunteer matching for ride assignments

class SmartMatchService: ObservableObject {
    static let shared = SmartMatchService()
    
    @Published var lastMatchResult: MatchResult?
    
    private var dataService = MockDataService.shared
    
    private init() {}
    
    // MARK: - Zone Definitions
    
    static let zones = ["Downtown", "North Side", "South Side", "East End", "West Hills"]
    
    // Zone adjacency map (which zones are "close" to each other)
    static let adjacentZones: [String: [String]] = [
        "Downtown": ["North Side", "South Side", "East End", "West Hills"],
        "North Side": ["Downtown", "East End"],
        "South Side": ["Downtown", "West Hills"],
        "East End": ["Downtown", "North Side"],
        "West Hills": ["Downtown", "South Side"]
    ]
    
    // MARK: - Match Result
    
    struct MatchResult: Identifiable {
        let id = UUID()
        let request: TransportRequest
        let rankedVolunteers: [ScoredVolunteer]
        let bestMatch: Volunteer?
        let matchScore: Int
        let reason: String
        let timestamp: Date
        
        var hasPerfectMatch: Bool {
            matchScore >= 90
        }
        
        var hasGoodMatch: Bool {
            matchScore >= 70
        }
    }
    
    struct ScoredVolunteer: Identifiable {
        let id: String
        let volunteer: Volunteer
        let score: Int
        let breakdown: ScoreBreakdown
        
        struct ScoreBreakdown {
            var availabilityScore: Int      // 0-30 pts
            var zoneMatchScore: Int         // 0-25 pts
            var preferredDriverScore: Int   // 0-20 pts
            var reliabilityScore: Int       // 0-15 pts
            var capacityScore: Int          // 0-10 pts (fewer active missions = higher)
            
            var total: Int {
                availabilityScore + zoneMatchScore + preferredDriverScore + reliabilityScore + capacityScore
            }
        }
    }
    
    // MARK: - Smart Match Algorithm
    
    func findBestMatch(for request: TransportRequest) -> MatchResult {
        let eligibleVolunteers = dataService.volunteers.filter { volunteer in
            // Must be available
            guard volunteer.availability == .available else { return false }
            
            // Check tier requirements for certain mission types
            if request.type == .stormCheckIn && volunteer.tier != .trustedResponder {
                return false
            }
            
            return true
        }
        
        // Score each volunteer
        var scoredVolunteers = eligibleVolunteers.map { volunteer -> ScoredVolunteer in
            let breakdown = calculateScore(volunteer: volunteer, for: request)
            return ScoredVolunteer(
                id: volunteer.id,
                volunteer: volunteer,
                score: breakdown.total,
                breakdown: breakdown
            )
        }
        
        // Sort by score descending
        scoredVolunteers.sort { $0.score > $1.score }
        
        let bestMatch = scoredVolunteers.first?.volunteer
        let matchScore = scoredVolunteers.first?.score ?? 0
        
        let reason = generateMatchReason(scoredVolunteers.first, request: request)
        
        let result = MatchResult(
            request: request,
            rankedVolunteers: scoredVolunteers,
            bestMatch: bestMatch,
            matchScore: matchScore,
            reason: reason,
            timestamp: Date()
        )
        
        // Note: Don't update @Published here - causes SwiftUI warnings when called during view updates
        return result
    }
    
    private func calculateScore(volunteer: Volunteer, for request: TransportRequest) -> ScoredVolunteer.ScoreBreakdown {
        var breakdown = ScoredVolunteer.ScoreBreakdown(
            availabilityScore: 0,
            zoneMatchScore: 0,
            preferredDriverScore: 0,
            reliabilityScore: 0,
            capacityScore: 0
        )
        
        // 1. Availability Score (0-30)
        switch volunteer.availability {
        case .available:
            breakdown.availabilityScore = 30
        case .unavailable:
            breakdown.availabilityScore = 0
        case .onMission:
            breakdown.availabilityScore = 5  // Small score if they'll be free soon
        }
        
        // 2. Zone Match Score (0-25)
        if volunteer.zone == request.pickupZone {
            // Perfect zone match
            breakdown.zoneMatchScore = 25
        } else if Self.adjacentZones[request.pickupZone]?.contains(volunteer.zone) == true {
            // Adjacent zone
            breakdown.zoneMatchScore = 15
        } else {
            // Far zone
            breakdown.zoneMatchScore = 5
        }
        
        // 3. Preferred Driver Score (0-20)
        if let preferredDriverId = dataService.patientPreferredDrivers[request.patientId],
           preferredDriverId == volunteer.id {
            breakdown.preferredDriverScore = 20
        }
        
        // 4. Reliability Score (0-15)
        let reliabilityPercent = volunteer.reliabilityScore * 100
        if reliabilityPercent >= 95 {
            breakdown.reliabilityScore = 15
        } else if reliabilityPercent >= 85 {
            breakdown.reliabilityScore = 12
        } else if reliabilityPercent >= 75 {
            breakdown.reliabilityScore = 8
        } else {
            breakdown.reliabilityScore = 4
        }
        
        // 5. Capacity Score (0-10) - fewer active missions = more capacity
        let activeMissions = dataService.requests.filter { 
            $0.assignedVolunteerId == volunteer.id && 
            $0.status == .assigned 
        }.count
        
        if activeMissions == 0 {
            breakdown.capacityScore = 10
        } else if activeMissions == 1 {
            breakdown.capacityScore = 6
        } else if activeMissions == 2 {
            breakdown.capacityScore = 3
        } else {
            breakdown.capacityScore = 0
        }
        
        return breakdown
    }
    
    private func generateMatchReason(_ scored: ScoredVolunteer?, request: TransportRequest) -> String {
        guard let scored = scored else {
            return "No available volunteers found"
        }
        
        var reasons: [String] = []
        
        if scored.breakdown.preferredDriverScore > 0 {
            reasons.append("Patient's preferred driver")
        }
        
        if scored.breakdown.zoneMatchScore >= 25 {
            reasons.append("In same zone")
        } else if scored.breakdown.zoneMatchScore >= 15 {
            reasons.append("Nearby zone")
        }
        
        if scored.breakdown.reliabilityScore >= 12 {
            reasons.append("\(scored.volunteer.reliabilityPercent)% reliability")
        }
        
        if scored.breakdown.capacityScore >= 8 {
            reasons.append("Available now")
        }
        
        return reasons.isEmpty ? "Best available match" : reasons.joined(separator: " • ")
    }
    
    // MARK: - Auto-Assignment
    
    func autoAssign(request: TransportRequest) -> TransportRequest? {
        let result = findBestMatch(for: request)
        
        guard let bestMatch = result.bestMatch, result.matchScore >= 50 else {
            return nil
        }
        
        // Update the request with assignment
        if let index = dataService.requests.firstIndex(where: { $0.id == request.id }) {
            dataService.requests[index].assignedVolunteerId = bestMatch.id
            dataService.requests[index].status = .assigned
            
            // Set volunteer to on-mission
            dataService.setVolunteerOnMission(volunteerId: bestMatch.id, onMission: true)
            
            return dataService.requests[index]
        }
        
        return nil
    }
    
    // MARK: - Batch Auto-Assignment
    
    func autoAssignAllOpen() -> [MatchResult] {
        let openRequests = dataService.requests.filter { $0.status == .open }
        
        return openRequests.compactMap { request in
            let result = findBestMatch(for: request)
            if let _ = autoAssign(request: request) {
                return result
            }
            return nil
        }
    }
    
    // MARK: - Suggest Best Match (without assigning)
    
    func suggestMatch(for request: TransportRequest) -> (volunteer: Volunteer, reason: String, score: Int)? {
        let result = findBestMatch(for: request)
        
        guard let volunteer = result.bestMatch else { return nil }
        
        return (volunteer, result.reason, result.matchScore)
    }
}

// MARK: - Zone Helper Extension

extension TransportRequest {
    // Infer zone from location string (simple demo logic)
    static func inferZone(from location: String) -> String {
        let location = location.lowercased()
        
        if location.contains("north") || location.contains("highland") {
            return "North Side"
        } else if location.contains("south") || location.contains("mt. washington") {
            return "South Side"
        } else if location.contains("east") || location.contains("shadyside") || location.contains("bloomfield") {
            return "East End"
        } else if location.contains("west") || location.contains("crafton") || location.contains("carnegie") {
            return "West Hills"
        } else {
            return "Downtown"
        }
    }
}
