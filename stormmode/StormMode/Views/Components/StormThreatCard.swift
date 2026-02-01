import SwiftUI

// MARK: - Storm Threat Card
// Displays AI-powered storm threat assessment with visual ring

struct StormThreatCard: View {
    @ObservedObject var aiService = AIStormService.shared
    @ObservedObject var dataService = MockDataService.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card
            mainContent
            
            // Expandable details
            if isExpanded {
                detailsContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3), value: isExpanded)
    }
    
    private var mainContent: some View {
        Button(action: { isExpanded.toggle() }) {
            HStack(spacing: 20) {
                // Threat Ring
                if let threat = aiService.stormThreatLevel {
                    ThreatRing(
                        score: threat.overallScore,
                        color: threat.scoreColor
                    )
                } else {
                    ThreatRing(score: 0, color: .statusOk)
                }
                
                // Threat Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("🌀 Storm Threat Level")
                            .font(.stormHeadline)
                            .foregroundColor(.textPrimary)
                        
                        if aiService.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    
                    if let threat = aiService.stormThreatLevel {
                        Text(String(format: "%.1f / 10", threat.overallScore))
                            .font(.stormTitle2)
                            .foregroundColor(threat.scoreColor)
                        
                        // Quick stats
                        HStack(spacing: 12) {
                            QuickStat(
                                icon: "person.fill",
                                value: "\(threat.vulnerablePatientsCount)",
                                label: "at risk"
                            )
                            QuickStat(
                                icon: "calendar",
                                value: "\(threat.atRiskAppointmentsCount)",
                                label: "impacted"
                            )
                        }
                    } else {
                        Text("Analyzing...")
                            .font(.stormCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                // Recommendation badge
                if let threat = aiService.stormThreatLevel {
                    RecommendationBadge(recommendation: threat.recommendation)
                }
                
                // Expand indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.textLight)
            }
            .padding(20)
            .background(cardBackground)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cardBackground: some View {
        Group {
            if let threat = aiService.stormThreatLevel, threat.overallScore >= 7 {
                // High alert: gradient tint
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [threat.scoreColor.opacity(0.2), threat.scoreColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            } else {
                // Normal: warm glass effect
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.stormBackground.opacity(0.4))
                    )
            }
        }
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    
    private var detailsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            
            if let threat = aiService.stormThreatLevel {
                // Score breakdown
                Text("Score Breakdown")
                    .font(.stormCaptionBold)
                    .foregroundColor(.textSecondary)
                
                VStack(spacing: 8) {
                    ScoreBreakdownRow(label: "Weather Conditions", score: threat.weatherScore / 10.0, maxScore: 4.0)
                    ScoreBreakdownRow(label: "Patient Vulnerability", score: threat.patientRiskScore / 10.0, maxScore: 2.5)
                    ScoreBreakdownRow(label: "Referral Impact", score: threat.referralImpactScore / 10.0, maxScore: 2.0)
                    ScoreBreakdownRow(label: "Transport Risk", score: threat.transportRiskScore / 10.0, maxScore: 1.5)
                }
                
                // Storm prediction
                if let prediction = threat.stormPrediction {
                    Divider()
                    
                    HStack {
                        Image(systemName: "cloud.bolt.rain.fill")
                            .foregroundColor(.stormActive)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Storm predicted \(prediction.onsetFormatted)")
                                .font(.stormBodyBold)
                                .foregroundColor(.textPrimary)
                            
                            Text("Confidence: \(prediction.confidencePercentage)%")
                                .font(.stormCaption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Action button
                if threat.recommendation == .activateNow && !dataService.stormState.isStormMode {
                    Button(action: activateStormMode) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Activate Storm Mode Now")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
                }
                
                // Confidence footer
                Text("AI confidence: \(Int(threat.confidenceLevel * 100))% • Updated \(formatTime(threat.analysisTimestamp))")
                    .font(.stormFootnote)
                    .foregroundColor(.textLight)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color.white)
    }
    
    private func activateStormMode() {
        dataService.activateStormMode()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Threat Ring

struct ThreatRing: View {
    let score: Double // 0-10
    let color: Color
    let size: CGFloat = 70
    
    var progress: Double {
        score / 10.0
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5), value: progress)
            
            // Center content
            VStack(spacing: 0) {
                Text(String(format: "%.1f", score))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text("/ 10")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textLight)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Quick Stat

struct QuickStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.textLight)
            
            Text(value)
                .font(.stormCaptionBold)
                .foregroundColor(.textPrimary)
                .lineLimit(1)
            
            Text(label)
                .font(.stormFootnote)
                .foregroundColor(.textSecondary)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Recommendation Badge

struct RecommendationBadge: View {
    let recommendation: StormRecommendation
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: recommendation.icon)
                .font(.title3)
                .foregroundColor(recommendation.color)
                .symbolEffect(.pulse, options: .repeating, value: recommendation == .activateNow)
            
            Text(recommendation.displayName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(recommendation.color)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .background(recommendation.color.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Score Breakdown Row

struct ScoreBreakdownRow: View {
    let label: String
    let score: Double
    let maxScore: Double
    
    var progress: Double {
        score / maxScore
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Text(String(format: "%.1f / %.0f", score, maxScore))
                    .font(.stormFootnote)
                    .foregroundColor(.textLight)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.textLight.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var progressColor: Color {
        if progress >= 0.7 { return .statusUrgent }
        if progress >= 0.5 { return .statusWarning }
        return .statusOk
    }
}

// MARK: - Patient Watch List Card

struct PatientWatchListCard: View {
    @ObservedObject var aiService = AIStormService.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.statusWarning)
                    
                    Text("AI Watch List")
                        .font(.stormHeadline)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(aiService.patientWatchList.count) patients")
                        .font(.stormCaptionBold)
                        .foregroundColor(.textSecondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textLight)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                ForEach(aiService.patientWatchList.prefix(5)) { profile in
                    PatientRiskRow(profile: profile)
                }
            } else {
                // Compact preview
                HStack(spacing: -8) {
                    ForEach(aiService.patientWatchList.prefix(4)) { profile in
                        PatientRiskAvatar(profile: profile)
                    }
                    
                    if aiService.patientWatchList.count > 4 {
                        Text("+\(aiService.patientWatchList.count - 4)")
                            .font(.stormFootnote)
                            .foregroundColor(.textSecondary)
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardYellow.opacity(0.85))
                .shadow(color: Color.cardYellow.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Patient Risk Row

struct PatientRiskRow: View {
    let profile: PatientRiskProfile
    
    var body: some View {
        HStack(spacing: 12) {
            // Risk level indicator
            ZStack {
                Circle()
                    .fill(profile.riskLevel.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: profile.riskLevel.icon)
                    .font(.body)
                    .foregroundColor(profile.riskLevel.color)
            }
            
            // Patient info
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.patient.fullName)
                    .font(.stormBodyBold)
                    .foregroundColor(.textPrimary)
                
                Text(profile.riskFactors.first ?? "At risk")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Risk score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(profile.scorePercentage)%")
                    .font(.stormCaptionBold)
                    .foregroundColor(profile.riskLevel.color)
                
                Text(profile.riskLevel.displayName)
                    .font(.stormFootnote)
                    .foregroundColor(.textLight)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Patient Risk Avatar

struct PatientRiskAvatar: View {
    let profile: PatientRiskProfile
    
    var body: some View {
        ZStack {
            Circle()
                .fill(profile.riskLevel.color)
                .frame(width: 36, height: 36)
            
            Text(profile.patient.initials)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

// MARK: - Smart Task Entry

struct SmartTaskEntry: View {
    @ObservedObject var aiService = AIStormService.shared
    @ObservedObject var dataService = MockDataService.shared
    
    @State private var inputText = ""
    @State private var parsedTask: ParsedTask?
    @State private var showConfirmation = false
    @State private var isProcessing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.cardLavender)
                
                Text("AI Task Entry")
                    .font(.stormHeadline)
                    .foregroundColor(.textPrimary)
            }
            
            // Input field
            HStack {
                TextField("Type a task naturally...", text: $inputText)
                    .font(.stormBody)
                    .onSubmit { parseInput() }
                
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if !inputText.isEmpty {
                    Button(action: parseInput) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.stormActive)
                    }
                }
            }
            .padding(12)
            .background(Color.stormBackground)
            .cornerRadius(12)
            
            // Parsed result
            if let parsed = parsedTask {
                ParsedTaskPreview(
                    parsed: parsed,
                    onConfirm: createTask,
                    onCancel: { parsedTask = nil }
                )
            }
            
            // Example prompts
            if parsedTask == nil && inputText.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Try saying:")
                        .font(.stormFootnote)
                        .foregroundColor(.textLight)
                    
                    ForEach(examplePrompts, id: \.self) { prompt in
                        Button(action: { inputText = prompt }) {
                            Text("\"\(prompt)\"")
                                .font(.stormCaption)
                                .foregroundColor(.textSecondary)
                                .italic()
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardMint.opacity(0.85))
                .shadow(color: Color.cardMint.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .alert("Task Created", isPresented: $showConfirmation) {
            Button("OK") {}
        } message: {
            Text("Your task has been added successfully.")
        }
    }
    
    private var examplePrompts: [String] {
        [
            "Call Mary about her cardiology referral",
            "Reschedule Robert Chen's appointment — storm coming",
            "Urgent: check on Eleanor, she missed last week"
        ]
    }
    
    private func parseInput() {
        guard !inputText.isEmpty else { return }
        
        isProcessing = true
        
        // Simulate AI processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            parsedTask = aiService.parseNaturalLanguageTask(inputText)
            isProcessing = false
        }
    }
    
    private func createTask() {
        guard let parsed = parsedTask else { return }
        
        if let task = aiService.createTaskFromParsed(parsed, assignedTo: dataService.currentUser.id) {
            dataService.tasks.append(task)
            inputText = ""
            parsedTask = nil
            showConfirmation = true
        }
    }
}

// MARK: - Parsed Task Preview

struct ParsedTaskPreview: View {
    let parsed: ParsedTask
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.statusOk)
                
                Text("AI understood:")
                    .font(.stormCaptionBold)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Text("\(parsed.confidencePercentage)% confident")
                    .font(.stormFootnote)
                    .foregroundColor(.textLight)
            }
            
            // Parsed fields
            VStack(alignment: .leading, spacing: 8) {
                ParsedField(label: "Task", value: parsed.type.displayName, icon: parsed.type.icon)
                
                if let patient = parsed.patient {
                    ParsedField(label: "Patient", value: patient.fullName, icon: "person.fill")
                }
                
                if let referralType = parsed.linkedReferralType {
                    ParsedField(label: "Referral", value: referralType.displayName, icon: referralType.icon)
                }
                
                ParsedField(label: "Priority", value: parsed.priority.displayName, icon: "flag.fill", color: parsed.priority.color)
                
                if !parsed.contextNotes.isEmpty {
                    ParsedField(label: "Notes", value: parsed.contextNotes.joined(separator: ", "), icon: "text.bubble.fill")
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: onConfirm) {
                    Text("Create Task")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(16)
        .background(Color.statusOk.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Parsed Field

struct ParsedField: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = .textPrimary
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(label + ":")
                .font(.stormCaption)
                .foregroundColor(.textSecondary)
            
            Text(value)
                .font(.stormCaptionBold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Scheduling Suggestions Card

struct SchedulingSuggestionsCard: View {
    let referral: Referral
    @ObservedObject var aiService = AIStormService.shared
    @State private var suggestions: [SchedulingSuggestion] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.cardBlue)
                
                Text("Smart Schedule Suggestions")
                    .font(.stormHeadline)
                    .foregroundColor(.textPrimary)
            }
            
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Analyzing optimal times...")
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                }
            } else if suggestions.isEmpty {
                Text("No optimal slots found in the next 7 days")
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
            } else {
                ForEach(suggestions.prefix(3)) { suggestion in
                    SchedulingSuggestionRow(suggestion: suggestion)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .cardShadow()
        .onAppear {
            loadSuggestions()
        }
    }
    
    private func loadSuggestions() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            suggestions = aiService.generateSchedulingSuggestions(for: referral)
            isLoading = false
        }
    }
}

// MARK: - Scheduling Suggestion Row

struct SchedulingSuggestionRow: View {
    let suggestion: SchedulingSuggestion
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                // Weather icon
                Image(systemName: suggestion.weatherCondition.icon)
                    .font(.title3)
                    .foregroundColor(suggestion.weatherCondition.color)
                    .frame(width: 32)
                
                // Time info
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.timeFormatted)
                        .font(.stormBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Text(suggestion.reason)
                        .font(.stormCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Confidence
                Text("\(suggestion.confidencePercentage)%")
                    .font(.stormCaptionBold)
                    .foregroundColor(.statusOk)
            }
            .padding(12)
            .background(Color.stormBackground)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            StormThreatCard()
            PatientWatchListCard()
            SmartTaskEntry()
        }
        .padding()
    }
    .background(Color.stormBackground)
}
