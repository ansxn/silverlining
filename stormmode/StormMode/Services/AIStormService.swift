import Foundation
import SwiftUI
import Combine

// MARK: - AI Storm Intelligence Service
// Provides predictive analytics for storm impact, patient risk scoring,
// smart scheduling, and natural language task parsing

class AIStormService: ObservableObject {
    static let shared = AIStormService()
    
    @Published var stormThreatLevel: StormThreatAssessment?
    @Published var patientWatchList: [PatientRiskProfile] = []
    @Published var schedulingSuggestions: [SchedulingSuggestion] = []
    @Published var isAnalyzing: Bool = false
    
    // AI Enhancement Properties
    @Published var aiReasoning: String?
    @Published var aiRecommendations: [String] = []
    @Published var isUsingRealAI: Bool = false
    
    private let weatherService = WeatherService.shared
    private let dataService = MockDataService.shared
    private let openAI = OpenAIService.shared
    private var cancellables = Set<AnyCancellable>()
    private init() {
        setupBindings()
        performInitialAnalysis()
    }
    
    private func setupBindings() {
        // Re-analyze when weather or data changes
        weatherService.$currentWeather
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.analyzeStormThreat()
            }
            .store(in: &cancellables)
        
        dataService.$referrals
            .combineLatest(dataService.$stormState)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.updatePatientWatchList()
            }
            .store(in: &cancellables)
    }
    
    private func performInitialAnalysis() {
        analyzeStormThreat()
        updatePatientWatchList()
    }
    
    // MARK: - Storm Threat Assessment
    
    func analyzeStormThreat() {
        isAnalyzing = true
        
        // Try real AI analysis first
        if openAI.isConfigured {
            Task {
                await performAIAnalysis()
            }
        } else {
            // Fallback to local heuristics
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.calculateStormThreat()
                self?.isAnalyzing = false
            }
        }
    }
    
    @MainActor
    private func performAIAnalysis() async {
        guard let weather = weatherService.currentWeather else {
            isAnalyzing = false
            return
        }
        
        // Prepare data for OpenAI
        let weatherSummary = WeatherSummary(
            condition: weather.description,
            temperature: weather.temperature,
            windSpeed: weather.windSpeed,
            precipProbability: weather.precipitationProbability
        )
        
        let patients = dataService.users
            .filter { $0.isVulnerable && $0.role == .patient }
            .map { PatientSummary(name: $0.fullName, conditions: "Vulnerable patient") }
        
        let referrals = dataService.referrals
            .filter { $0.stormSensitive && !$0.status.isTerminal }
            .map { ReferralSummary(type: $0.referralType.displayName, urgency: $0.priority.displayName) }
        
        // Call OpenAI
        if let analysis = await openAI.analyzeStormRisk(
            weather: weatherSummary,
            patients: patients,
            referrals: referrals
        ) {
            // Use AI analysis
            self.aiReasoning = analysis.reasoning
            self.aiRecommendations = analysis.recommendations
            self.isUsingRealAI = true
            
            // Still calculate local assessment but override score with AI
            calculateStormThreat(aiOverrideScore: analysis.overallRiskScore)
        } else {
            // Fallback to local
            self.isUsingRealAI = false
            calculateStormThreat()
        }
        
        isAnalyzing = false
    }
    
    private func calculateStormThreat(aiOverrideScore: Double? = nil) {
        guard let weather = weatherService.currentWeather else {
            stormThreatLevel = nil
            return
        }
        
        // Get storm prediction from weather service
        let stormPrediction = weatherService.predictStorm(within: 72) // 3 days
        
        // Calculate base weather severity
        let weatherSeverity = weatherService.calculateWeatherSeverity()
        
        // Count vulnerable patients and at-risk referrals
        let vulnerablePatients = dataService.users.filter { $0.isVulnerable && $0.role == .patient }
        let upcomingReferrals = getUpcomingStormSensitiveReferrals(daysAhead: 3)
        let pendingRequests = dataService.requests.filter { $0.status == .open || $0.status == .assigned }
        
        // Calculate component scores (each already weighted, sum = 100 max)
        let weatherScore = weatherSeverity / 100.0 * 40  // 40% weight
        let patientScore = min(Double(vulnerablePatients.count) / 20.0, 1.0) * 25  // 25% weight
        let referralScore = min(Double(upcomingReferrals.count) / 10.0, 1.0) * 20  // 20% weight
        let transportScore = min(Double(pendingRequests.count) / 5.0, 1.0) * 15  // 15% weight
        
        // Use AI score if provided, otherwise calculate locally
        let totalScore = aiOverrideScore ?? (weatherScore + patientScore + referralScore + transportScore) / 10.0
        
        // Determine recommendation
        let recommendation: StormRecommendation
        if totalScore >= 7.0 {
            recommendation = .activateNow
        } else if totalScore >= 5.0 {
            recommendation = .standby
        } else if totalScore >= 3.0 {
            recommendation = .monitor
        } else {
            recommendation = .allClear
        }
        
        // Build threat assessment
        stormThreatLevel = StormThreatAssessment(
            overallScore: totalScore,
            weatherScore: weatherScore,
            patientRiskScore: patientScore,
            referralImpactScore: referralScore,
            transportRiskScore: transportScore,
            vulnerablePatientsCount: vulnerablePatients.count,
            atRiskAppointmentsCount: upcomingReferrals.count,
            pendingTransportCount: pendingRequests.count,
            recommendation: recommendation,
            stormPrediction: stormPrediction,
            currentCondition: weather.condition,
            analysisTimestamp: Date(),
            confidenceLevel: calculateConfidenceLevel(stormPrediction: stormPrediction)
        )
    }
    
    private func getUpcomingStormSensitiveReferrals(daysAhead: Int) -> [Referral] {
        let futureDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date()) ?? Date()
        
        return dataService.referrals.filter { referral in
            guard referral.stormSensitive,
                  !referral.status.isTerminal,
                  let appointmentDate = referral.appointmentDateTime else {
                return false
            }
            return appointmentDate > Date() && appointmentDate <= futureDate
        }
    }
    
    private func calculateConfidenceLevel(stormPrediction: StormPrediction?) -> Double {
        // Base confidence from weather data quality
        var confidence = weatherService.isDemoMode ? 0.6 : 0.85
        
        // Adjust based on prediction availability
        if let prediction = stormPrediction {
            confidence = (confidence + prediction.confidence) / 2
        }
        
        return confidence
    }
    
    // MARK: - Patient Risk Scoring
    
    func updatePatientWatchList() {
        let patients = dataService.users.filter { $0.role == .patient }
        
        var profiles: [PatientRiskProfile] = patients.compactMap { patient in
            calculatePatientRisk(for: patient)
        }
        
        // Sort by risk score descending
        profiles.sort { $0.overallRiskScore > $1.overallRiskScore }
        
        // Take top 10 highest risk
        patientWatchList = Array(profiles.prefix(10))
    }
    
    func calculatePatientRisk(for patient: User) -> PatientRiskProfile? {
        // Get patient's referrals and requests
        let referrals = dataService.referrals.filter { $0.patientId == patient.id }
        let requests = dataService.requests.filter { $0.patientId == patient.id }
        
        // Calculate individual risk factors
        let vulnerabilityScore = patient.isVulnerable ? 25.0 : 5.0
        
        // Medical history (based on referral types and priority)
        let medicalScore = calculateMedicalRiskScore(from: referrals)
        
        // Adherence score (based on past appointment attendance)
        let adherenceScore = calculateAdherenceRiskScore(from: referrals)
        
        // Weather sensitivity (based on storm-sensitive referrals)
        let weatherSensitivityScore = calculateWeatherSensitivityScore(from: referrals)
        
        // Isolation score (based on transport requests)
        let isolationScore = calculateIsolationScore(from: requests)
        
        // Social support (based on emergency contact)
        let socialSupportScore = patient.emergencyContact != nil ? 5.0 : 15.0
        
        let overallScore = (vulnerabilityScore + medicalScore + adherenceScore + 
                          weatherSensitivityScore + isolationScore + socialSupportScore) / 6.0
        
        // Determine risk level
        let riskLevel: RiskLevel
        if overallScore >= 20 {
            riskLevel = .critical
        } else if overallScore >= 15 {
            riskLevel = .high
        } else if overallScore >= 10 {
            riskLevel = .medium
        } else {
            riskLevel = .low
        }
        
        // Generate recommended actions
        let actions = generateRecommendedActions(
            patient: patient,
            referrals: referrals,
            riskLevel: riskLevel
        )
        
        // Only include patients with meaningful risk
        guard overallScore >= 8 else { return nil }
        
        return PatientRiskProfile(
            patient: patient,
            overallRiskScore: overallScore,
            vulnerabilityScore: vulnerabilityScore,
            medicalComplexityScore: medicalScore,
            adherenceScore: adherenceScore,
            weatherSensitivity: weatherSensitivityScore,
            isolationLevel: isolationScore,
            socialSupportScore: socialSupportScore,
            riskLevel: riskLevel,
            riskFactors: identifyRiskFactors(patient: patient, referrals: referrals),
            recommendedActions: actions,
            lastAssessment: Date()
        )
    }
    
    private func calculateMedicalRiskScore(from referrals: [Referral]) -> Double {
        guard !referrals.isEmpty else { return 5.0 }
        
        // High priority referrals increase risk
        let highPriorityCount = referrals.filter { $0.priority == .high }.count
        let mediumPriorityCount = referrals.filter { $0.priority == .medium }.count
        
        // Certain referral types are higher risk
        let highRiskTypes: [ReferralType] = [.cardiology, .mentalHealth]
        let highRiskCount = referrals.filter { highRiskTypes.contains($0.referralType) }.count
        
        var score = 5.0
        score += Double(highPriorityCount) * 5.0
        score += Double(mediumPriorityCount) * 2.0
        score += Double(highRiskCount) * 3.0
        
        return min(score, 25.0)
    }
    
    private func calculateAdherenceRiskScore(from referrals: [Referral]) -> Double {
        guard !referrals.isEmpty else { return 15.0 } // Unknown adherence is risky
        
        let missedCount = referrals.filter { $0.status == .missed }.count
        let attendedCount = referrals.filter { $0.status == .attended || $0.status == .closed }.count
        let totalCompleted = missedCount + attendedCount
        
        guard totalCompleted > 0 else { return 15.0 }
        
        let missRate = Double(missedCount) / Double(totalCompleted)
        return missRate * 25.0
    }
    
    private func calculateWeatherSensitivityScore(from referrals: [Referral]) -> Double {
        let stormSensitiveCount = referrals.filter { $0.stormSensitive }.count
        let activeCount = referrals.filter { !$0.status.isTerminal }.count
        
        guard activeCount > 0 else { return 5.0 }
        
        let sensitivityRatio = Double(stormSensitiveCount) / Double(activeCount)
        return sensitivityRatio * 25.0
    }
    
    private func calculateIsolationScore(from requests: [TransportRequest]) -> Double {
        // More transport requests = higher isolation
        let recentRequests = requests.filter { 
            $0.createdAt > Date().addingTimeInterval(-86400 * 30) // Last 30 days
        }
        
        return min(Double(recentRequests.count) * 4.0, 25.0)
    }
    
    private func identifyRiskFactors(patient: User, referrals: [Referral]) -> [String] {
        var factors: [String] = []
        
        if patient.isVulnerable {
            factors.append("Marked as vulnerable")
        }
        
        if patient.emergencyContact == nil {
            factors.append("No emergency contact on file")
        }
        
        let missedCount = referrals.filter { $0.status == .missed }.count
        if missedCount > 0 {
            factors.append("Has \(missedCount) missed appointment(s)")
        }
        
        let stormSensitive = referrals.filter { $0.stormSensitive && !$0.status.isTerminal }
        if !stormSensitive.isEmpty {
            factors.append("\(stormSensitive.count) storm-sensitive referral(s)")
        }
        
        let highPriority = referrals.filter { $0.priority == .high && !$0.status.isTerminal }
        if !highPriority.isEmpty {
            factors.append("\(highPriority.count) high-priority referral(s)")
        }
        
        return factors
    }
    
    private func generateRecommendedActions(
        patient: User,
        referrals: [Referral],
        riskLevel: RiskLevel
    ) -> [RecommendedAction] {
        var actions: [RecommendedAction] = []
        
        switch riskLevel {
        case .critical:
            actions.append(.init(type: .callPatient, priority: .high, reason: "Critical risk level"))
        case .high:
            actions.append(.init(type: .callPatient, priority: .medium, reason: "High risk level"))
        default:
            break
        }
        
        // Check for missed appointments
        if referrals.contains(where: { $0.status == .missed }) {
            actions.append(.init(type: .reschedule, priority: .high, reason: "Missed appointment"))
        }
        
        // Check for storm-sensitive upcoming appointments
        let upcoming = referrals.filter {
            $0.stormSensitive && 
            !$0.status.isTerminal &&
            $0.appointmentDateTime ?? Date.distantFuture < Date().addingTimeInterval(86400 * 3)
        }
        if !upcoming.isEmpty && stormThreatLevel?.recommendation == .activateNow {
            actions.append(.init(type: .reschedule, priority: .high, reason: "Storm threat to upcoming appointment"))
        }
        
        // Check for no emergency contact
        if patient.emergencyContact == nil {
            actions.append(.init(type: .updateContact, priority: .low, reason: "Missing emergency contact"))
        }
        
        return actions
    }
    
    // MARK: - Intelligent Scheduling
    
    func generateSchedulingSuggestions(for referral: Referral) -> [SchedulingSuggestion] {
        var suggestions: [SchedulingSuggestion] = []
        
        // Get forecast for next 7 days
        let forecasts = weatherService.weatherForecast
        
        // Find optimal windows (good weather + available volunteers)
        let calendar = Calendar.current
        let now = Date()
        
        for dayOffset in 1...7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            // Check morning slot (9 AM)
            if let morningSlot = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate) {
                let score = evaluateTimeSlot(date: morningSlot, forecasts: forecasts)
                if score > 0.5 {
                    suggestions.append(SchedulingSuggestion(
                        suggestedTime: morningSlot,
                        confidenceScore: score,
                        weatherCondition: forecastCondition(for: morningSlot, in: forecasts),
                        reason: "Good weather, typical morning availability"
                    ))
                }
            }
            
            // Check afternoon slot (2 PM)
            if let afternoonSlot = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: targetDate) {
                let score = evaluateTimeSlot(date: afternoonSlot, forecasts: forecasts)
                if score > 0.5 {
                    suggestions.append(SchedulingSuggestion(
                        suggestedTime: afternoonSlot,
                        confidenceScore: score,
                        weatherCondition: forecastCondition(for: afternoonSlot, in: forecasts),
                        reason: "Clear afternoon conditions"
                    ))
                }
            }
        }
        
        // Sort by confidence score
        suggestions.sort { $0.confidenceScore > $1.confidenceScore }
        
        return Array(suggestions.prefix(5))
    }
    
    private func evaluateTimeSlot(date: Date, forecasts: [WeatherForecast]) -> Double {
        // Find closest forecast
        let closestForecast = forecasts.min { a, b in
            abs(a.date.timeIntervalSince(date)) < abs(b.date.timeIntervalSince(date))
        }
        
        guard let forecast = closestForecast else { return 0.5 }
        
        // Score based on weather severity
        let weatherScore = 1.0 - forecast.condition.severity
        
        // Score based on precipitation probability
        let precipScore = 1.0 - Double(forecast.precipitationProbability) / 100.0
        
        // Score based on wind
        let windScore = max(0, 1.0 - forecast.windSpeed / 80.0)
        
        return (weatherScore * 0.4 + precipScore * 0.4 + windScore * 0.2)
    }
    
    private func forecastCondition(for date: Date, in forecasts: [WeatherForecast]) -> WeatherCondition {
        let closest = forecasts.min { a, b in
            abs(a.date.timeIntervalSince(date)) < abs(b.date.timeIntervalSince(date))
        }
        return closest?.condition ?? .cloudy
    }
    
    // MARK: - Natural Language Task Parsing
    
    func parseNaturalLanguageTask(_ input: String) -> ParsedTask? {
        let lowercased = input.lowercased()
        
        // Determine task type
        let taskType: TaskType
        if lowercased.contains("call") || lowercased.contains("phone") || lowercased.contains("check on") {
            taskType = .callPatient
        } else if lowercased.contains("reschedule") || lowercased.contains("move appointment") {
            taskType = .rescheduleReferral
        } else if lowercased.contains("ride") || lowercased.contains("transport") || lowercased.contains("pickup") {
            taskType = .arrangeRide
        } else if lowercased.contains("follow up") || lowercased.contains("follow-up") {
            taskType = .followUp
        } else if lowercased.contains("storm") || lowercased.contains("check-in") || lowercased.contains("checkin") {
            taskType = .stormCheckIn
        } else {
            taskType = .followUp // Default
        }
        
        // Find patient name
        var matchedPatient: User?
        for patient in dataService.users.filter({ $0.role == .patient }) {
            let nameParts = patient.fullName.lowercased().split(separator: " ")
            for part in nameParts {
                if lowercased.contains(String(part)) && part.count >= 3 {
                    matchedPatient = patient
                    break
                }
            }
            if matchedPatient != nil { break }
        }
        
        // Find referral type mention
        var matchedReferralType: ReferralType?
        for type in ReferralType.allCases {
            if lowercased.contains(type.displayName.lowercased()) ||
               lowercased.contains(type.rawValue.replacingOccurrences(of: "_", with: " ")) {
                matchedReferralType = type
                break
            }
        }
        
        // Find linked referral
        var linkedReferral: Referral?
        if let patient = matchedPatient {
            let patientReferrals = dataService.referrals.filter { $0.patientId == patient.id && !$0.status.isTerminal }
            
            if let type = matchedReferralType {
                linkedReferral = patientReferrals.first { $0.referralType == type }
            } else {
                linkedReferral = patientReferrals.first
            }
        }
        
        // Determine priority
        let priority: Priority
        if lowercased.contains("urgent") || lowercased.contains("asap") || 
           lowercased.contains("immediately") || lowercased.contains("storm") ||
           lowercased.contains("emergency") {
            priority = .high
        } else if lowercased.contains("soon") || lowercased.contains("missed") {
            priority = .medium
        } else {
            priority = .low
        }
        
        // Extract contextual notes
        var contextNotes: [String] = []
        if lowercased.contains("missed") {
            contextNotes.append("Missed previous appointment")
        }
        if lowercased.contains("storm") {
            contextNotes.append("Storm-related urgency")
        }
        
        return ParsedTask(
            type: taskType,
            patient: matchedPatient,
            linkedReferral: linkedReferral,
            linkedReferralType: matchedReferralType,
            priority: priority,
            contextNotes: contextNotes,
            originalInput: input,
            confidence: calculateParsingConfidence(patient: matchedPatient, taskType: taskType)
        )
    }
    
    private func calculateParsingConfidence(patient: User?, taskType: TaskType) -> Double {
        var confidence = 0.5
        
        if patient != nil {
            confidence += 0.3
        }
        
        // Task type detection is fairly reliable
        confidence += 0.2
        
        return min(confidence, 1.0)
    }
    
    func createTaskFromParsed(_ parsed: ParsedTask, assignedTo: String) -> StormTask? {
        guard parsed.patient != nil || parsed.type == .stormCheckIn else { return nil }
        
        return StormTask(
            id: UUID().uuidString,
            type: parsed.type,
            patientId: parsed.patient?.id,
            linkedReferralId: parsed.linkedReferral?.id,
            linkedRequestId: nil,
            status: .open,
            priority: parsed.priority,
            assignedTo: assignedTo,
            createdAt: Date(),
            dueAt: Date().addingTimeInterval(parsed.priority == .high ? 3600 : 86400),
            completedAt: nil,
            notes: parsed.contextNotes.joined(separator: "; ")
        )
    }
}

// MARK: - Data Models

struct StormThreatAssessment {
    let overallScore: Double // 0-10 scale
    let weatherScore: Double
    let patientRiskScore: Double
    let referralImpactScore: Double
    let transportRiskScore: Double
    let vulnerablePatientsCount: Int
    let atRiskAppointmentsCount: Int
    let pendingTransportCount: Int
    let recommendation: StormRecommendation
    let stormPrediction: StormPrediction?
    let currentCondition: WeatherCondition
    let analysisTimestamp: Date
    let confidenceLevel: Double
    
    var scorePercentage: Int {
        Int(overallScore * 10)
    }
    
    var scoreColor: Color {
        switch overallScore {
        case 7...: return .statusUrgent
        case 5..<7: return .statusWarning
        case 3..<5: return .cardYellow
        default: return .statusOk
        }
    }
}

enum StormRecommendation: String {
    case activateNow = "activate_now"
    case standby = "standby"
    case monitor = "monitor"
    case allClear = "all_clear"
    
    var displayName: String {
        switch self {
        case .activateNow: return "Activate Now"
        case .standby: return "Stand By"
        case .monitor: return "Monitor"
        case .allClear: return "All Clear"
        }
    }
    
    var shortName: String {
        switch self {
        case .activateNow: return "Activate!"
        case .standby: return "Stand By"
        case .monitor: return "Monitor"
        case .allClear: return "All Clear"
        }
    }
    
    var color: Color {
        switch self {
        case .activateNow: return .statusUrgent
        case .standby: return .statusWarning
        case .monitor: return .cardYellow
        case .allClear: return .statusOk
        }
    }
    
    var icon: String {
        switch self {
        case .activateNow: return "exclamationmark.triangle.fill"
        case .standby: return "clock.badge.exclamationmark"
        case .monitor: return "eye.fill"
        case .allClear: return "checkmark.circle.fill"
        }
    }
}

struct PatientRiskProfile: Identifiable {
    var id: String { patient.id }
    
    let patient: User
    let overallRiskScore: Double
    let vulnerabilityScore: Double
    let medicalComplexityScore: Double
    let adherenceScore: Double
    let weatherSensitivity: Double
    let isolationLevel: Double
    let socialSupportScore: Double
    let riskLevel: RiskLevel
    let riskFactors: [String]
    let recommendedActions: [RecommendedAction]
    let lastAssessment: Date
    
    var scorePercentage: Int {
        Int(overallRiskScore * 4) // Scale to 100
    }
}

enum RiskLevel: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .low: return .statusOk
        case .medium: return .cardYellow
        case .high: return .statusWarning
        case .critical: return .statusUrgent
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

struct RecommendedAction: Identifiable {
    let id = UUID()
    let type: ActionType
    let priority: Priority
    let reason: String
    
    enum ActionType: String {
        case callPatient = "call_patient"
        case reschedule = "reschedule"
        case arrangeTransport = "arrange_transport"
        case updateContact = "update_contact"
        case stormCheckIn = "storm_checkin"
        
        var displayName: String {
            switch self {
            case .callPatient: return "Call Patient"
            case .reschedule: return "Reschedule Appointment"
            case .arrangeTransport: return "Arrange Transport"
            case .updateContact: return "Update Contact Info"
            case .stormCheckIn: return "Storm Check-In"
            }
        }
        
        var icon: String {
            switch self {
            case .callPatient: return "phone.fill"
            case .reschedule: return "calendar.badge.clock"
            case .arrangeTransport: return "car.fill"
            case .updateContact: return "person.text.rectangle.fill"
            case .stormCheckIn: return "cloud.bolt.fill"
            }
        }
    }
}

struct SchedulingSuggestion: Identifiable {
    let id = UUID()
    let suggestedTime: Date
    let confidenceScore: Double
    let weatherCondition: WeatherCondition
    let reason: String
    
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: suggestedTime)
    }
    
    var confidencePercentage: Int {
        Int(confidenceScore * 100)
    }
}

struct ParsedTask {
    let type: TaskType
    let patient: User?
    let linkedReferral: Referral?
    let linkedReferralType: ReferralType?
    let priority: Priority
    let contextNotes: [String]
    let originalInput: String
    let confidence: Double
    
    var confidencePercentage: Int {
        Int(confidence * 100)
    }
    
    var summary: String {
        var parts: [String] = [type.displayName]
        if let patient = patient {
            parts.append("for \(patient.fullName)")
        }
        if let referralType = linkedReferralType {
            parts.append("(\(referralType.displayName))")
        }
        return parts.joined(separator: " ")
    }
}
