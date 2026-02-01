import Foundation

// MARK: - Twilio Service
// Sends SMS check-ins via Twilio Functions

class TwilioService {
    static let shared = TwilioService()
    
    // Twilio Function URL - deployed and ready!
    private let functionURL = "https://send-checkin-2873.twil.io/send-checkin"
    
    private init() {}
    
    // MARK: - Send Storm Check-In SMS
    
    struct SMSResult {
        let success: Bool
        let messageSid: String?
        let error: String?
    }
    
    func sendStormCheckIn(
        patientName: String,
        patientPhone: String,
        customMessage: String? = nil
    ) async -> SMSResult {
        guard let url = URL(string: functionURL) else {
            return SMSResult(success: false, messageSid: nil, error: "Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Build form data
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "patientName", value: patientName),
            URLQueryItem(name: "patientPhone", value: patientPhone)
        ]
        
        if let message = customMessage {
            components.queryItems?.append(URLQueryItem(name: "message", value: message))
        }
        
        request.httpBody = components.query?.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return SMSResult(success: false, messageSid: nil, error: "Invalid response")
            }
            
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let success = json["success"] as? Bool ?? false
                    let sid = json["messageSid"] as? String
                    let error = json["error"] as? String
                    return SMSResult(success: success, messageSid: sid, error: error)
                }
            }
            
            return SMSResult(success: false, messageSid: nil, error: "HTTP \(httpResponse.statusCode)")
            
        } catch {
            return SMSResult(success: false, messageSid: nil, error: error.localizedDescription)
        }
    }
    
    // MARK: - Batch Send (for Storm Mode activation)
    
    func sendBatchCheckIns(
        patients: [(name: String, phone: String)]
    ) async -> (sent: Int, failed: Int) {
        var sent = 0
        var failed = 0
        
        for patient in patients {
            let result = await sendStormCheckIn(
                patientName: patient.name,
                patientPhone: patient.phone
            )
            
            if result.success {
                sent += 1
                print("✅ SMS sent to \(patient.name)")
            } else {
                failed += 1
                print("❌ SMS failed for \(patient.name): \(result.error ?? "Unknown")")
            }
            
            // Small delay to avoid rate limiting
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        return (sent, failed)
    }
}
