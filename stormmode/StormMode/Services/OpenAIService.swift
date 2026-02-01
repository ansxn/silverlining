import Foundation

// MARK: - OpenAI Network Service
// Provides AI-powered analysis using OpenAI GPT-4 API

class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    @Published var isProcessing = false
    @Published var lastError: String?
    
    // API Configuration
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini" // Cost-effective and fast
    
    var isConfigured: Bool {
        !apiKey.isEmpty
    }
    
    private init() {
        // Use environment variable for API key (set OPENAI_API_KEY in Xcode scheme)
        self.apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    // MARK: - Storm Risk Analysis
    
    func analyzeStormRisk(
        weather: WeatherSummary,
        patients: [PatientSummary],
        referrals: [ReferralSummary]
    ) async -> StormRiskAnalysis? {
        guard isConfigured else { return nil }
        
        let prompt = buildStormAnalysisPrompt(weather: weather, patients: patients, referrals: referrals)
        
        guard let response = await sendChatRequest(
            systemPrompt: stormAnalysisSystemPrompt,
            userPrompt: prompt
        ) else { return nil }
        
        return parseStormAnalysisResponse(response)
    }
    
    // MARK: - Natural Language Task Parsing
    
    func parseTaskNaturalLanguage(
        input: String,
        availablePatients: [PatientSummary]
    ) async -> TaskParseResult? {
        guard isConfigured else { return nil }
        
        let prompt = buildTaskParsePrompt(input: input, patients: availablePatients)
        
        guard let response = await sendChatRequest(
            systemPrompt: taskParsingSystemPrompt,
            userPrompt: prompt
        ) else { return nil }
        
        return parseTaskResponse(response)
    }
    
    // MARK: - Private Methods
    
    private func sendChatRequest(systemPrompt: String, userPrompt: String) async -> String? {
        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }
        
        print("🤖 [OpenAI] Starting API request...")
        print("🤖 [OpenAI] Model: \(model)")
        
        guard let url = URL(string: baseURL) else { 
            print("❌ [OpenAI] Invalid URL")
            return nil 
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.3,
            "max_tokens": 1000
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("🤖 [OpenAI] Sending request to API...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [OpenAI] Invalid response type")
                return nil
            }
            
            print("🤖 [OpenAI] Response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ [OpenAI] API Error: \(errorBody)")
                await MainActor.run { lastError = "API request failed: \(httpResponse.statusCode)" }
                return nil
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let choices = json?["choices"] as? [[String: Any]]
            let message = choices?.first?["message"] as? [String: Any]
            let content = message?["content"] as? String
            
            print("✅ [OpenAI] Response received: \(content?.prefix(100) ?? "nil")...")
            return content
            
        } catch {
            print("❌ [OpenAI] Error: \(error.localizedDescription)")
            await MainActor.run { lastError = error.localizedDescription }
            return nil
        }
    }
    
    // MARK: - Prompts
    
    private var stormAnalysisSystemPrompt: String {
        """
        You are a healthcare emergency coordinator AI. Analyze storm threats and patient risks for a rural health clinic.
        
        Respond ONLY in this JSON format:
        {
            "overallRiskScore": 0-10,
            "reasoning": "brief explanation",
            "urgentPatients": ["patient names needing immediate attention"],
            "recommendations": ["actionable recommendations"],
            "weatherImpact": "low/medium/high/critical"
        }
        """
    }
    
    private var taskParsingSystemPrompt: String {
        """
        You are a healthcare task assistant. Parse natural language into structured tasks.
        
        Respond ONLY in this JSON format:
        {
            "taskType": "call/schedule/checkIn/documentation/transport/medication/urgent",
            "patientName": "name if mentioned or null",
            "priority": "low/normal/high/urgent",
            "description": "clear task description",
            "dueTimeframe": "immediate/today/thisWeek/asNeeded"
        }
        """
    }
    
    private func buildStormAnalysisPrompt(
        weather: WeatherSummary,
        patients: [PatientSummary],
        referrals: [ReferralSummary]
    ) -> String {
        """
        Current Weather:
        - Condition: \(weather.condition)
        - Temperature: \(weather.temperature)°C
        - Wind Speed: \(weather.windSpeed) km/h
        - Precipitation Probability: \(weather.precipProbability)%
        
        Vulnerable Patients (\(patients.count)):
        \(patients.map { "- \($0.name): \($0.conditions)" }.joined(separator: "\n"))
        
        Pending Referrals (\(referrals.count)):
        \(referrals.map { "- \($0.type): \($0.urgency)" }.joined(separator: "\n"))
        
        Analyze the storm risk and provide recommendations.
        """
    }
    
    private func buildTaskParsePrompt(input: String, patients: [PatientSummary]) -> String {
        """
        Known patients: \(patients.map { $0.name }.joined(separator: ", "))
        
        Parse this task request: "\(input)"
        """
    }
    
    // MARK: - Response Parsing
    
    private func parseStormAnalysisResponse(_ response: String) -> StormRiskAnalysis? {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return StormRiskAnalysis(
            overallRiskScore: json["overallRiskScore"] as? Double ?? 0,
            reasoning: json["reasoning"] as? String ?? "",
            urgentPatients: json["urgentPatients"] as? [String] ?? [],
            recommendations: json["recommendations"] as? [String] ?? [],
            weatherImpact: json["weatherImpact"] as? String ?? "low"
        )
    }
    
    private func parseTaskResponse(_ response: String) -> TaskParseResult? {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return TaskParseResult(
            taskType: json["taskType"] as? String ?? "call",
            patientName: json["patientName"] as? String,
            priority: json["priority"] as? String ?? "normal",
            description: json["description"] as? String ?? "",
            dueTimeframe: json["dueTimeframe"] as? String ?? "today"
        )
    }
}

// MARK: - Data Models

struct WeatherSummary {
    let condition: String
    let temperature: Double
    let windSpeed: Double
    let precipProbability: Int
}

struct PatientSummary {
    let name: String
    let conditions: String
}

struct ReferralSummary {
    let type: String
    let urgency: String
}

struct StormRiskAnalysis {
    let overallRiskScore: Double
    let reasoning: String
    let urgentPatients: [String]
    let recommendations: [String]
    let weatherImpact: String
}

struct TaskParseResult {
    let taskType: String
    let patientName: String?
    let priority: String
    let description: String
    let dueTimeframe: String
}
