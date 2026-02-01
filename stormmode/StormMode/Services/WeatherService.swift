import Foundation
import CoreLocation
import SwiftUI

// MARK: - Weather Service
// Fetches real-time weather data from OpenWeatherMap API

class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherService()
    
    // MARK: - Published Properties
    @Published var currentWeather: WeatherData?
    @Published var weatherForecast: [WeatherForecast] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var userLocation: CLLocation?
    
    // MARK: - Location Manager
    private let locationManager = CLLocationManager()
    
    // MARK: - API Configuration
    // Get your free API key from: https://openweathermap.org/api
    // For production, store this in a secure configuration
    private var apiKey: String {
        // Check for environment variable or use demo key
        ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] ?? "18eae11d79c8755c125af8783405d101"
    }
    
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    
    // Demo mode is FALSE since we have a real API key
    var isDemoMode: Bool {
        false // API key is now configured
    }
    
    // London, Ontario coordinates
    private let londonOntarioLocation = CLLocation(latitude: 42.9849, longitude: -81.2453)
    
    private override init() {
        super.init()
        setupLocationManager()
        
        // Load demo weather first so UI has data immediately
        loadDemoWeather()
        
        // Request location permission on launch
        requestLocationPermission()
    }
    
    // MARK: - Location Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // Request permission - this will show the dialog
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized, get location
            locationManager.requestLocation()
        case .denied, .restricted:
            // Use London, Ontario as default
            setLocationToLondonOntario()
        @unknown default:
            setLocationToLondonOntario()
        }
    }
    
    /// Manually set location to London, Ontario (for simulator or denied permissions)
    func setLocationToLondonOntario() {
        userLocation = londonOntarioLocation
        Task {
            await fetchWeather(for: londonOntarioLocation)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            // Use London, Ontario as default when permission denied
            setLocationToLondonOntario()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        userLocation = location
        
        Task {
            await fetchWeather(for: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        // Use London, Ontario as fallback
        setLocationToLondonOntario()
    }
    
    // MARK: - API Calls
    
    @MainActor
    func fetchWeather(for location: CLLocation) async {
        guard !isDemoMode else {
            loadDemoWeather()
            return
        }
        
        isLoading = true
        error = nil
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        // Fetch current weather
        let currentURL = "\(baseURL)/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        
        do {
            guard let url = URL(string: currentURL) else { throw WeatherError.invalidURL }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
            currentWeather = WeatherData(from: response)
            
            // Fetch forecast
            await fetchForecast(lat: lat, lon: lon)
            
        } catch {
            self.error = error.localizedDescription
            loadDemoWeather()
        }
        
        isLoading = false
    }
    
    @MainActor
    private func fetchForecast(lat: Double, lon: Double) async {
        let forecastURL = "\(baseURL)/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        
        do {
            guard let url = URL(string: forecastURL) else { throw WeatherError.invalidURL }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenWeatherForecastResponse.self, from: data)
            weatherForecast = response.list.map { WeatherForecast(from: $0) }
        } catch {
            print("Forecast fetch error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Demo Data
    
    func loadDemoWeather() {
        // Simulate realistic weather for demo
        let conditions: [WeatherCondition] = [.clear, .cloudy, .rain, .snow, .storm]
        let randomCondition = conditions.randomElement() ?? .cloudy
        
        currentWeather = WeatherData(
            temperature: Double.random(in: -15...25),
            feelsLike: Double.random(in: -20...20),
            humidity: Int.random(in: 40...90),
            windSpeed: Double.random(in: 5...50),
            windGust: Double.random(in: 10...80),
            condition: randomCondition,
            description: randomCondition.description,
            icon: randomCondition.icon,
            visibility: Int.random(in: 1000...10000),
            pressure: Int.random(in: 990...1030),
            cloudCoverage: randomCondition == .clear ? 10 : Int.random(in: 50...100),
            precipitationProbability: randomCondition.precipitationProbability,
            location: "London, ON",
            timestamp: Date()
        )
        
        // Generate 5-day forecast
        weatherForecast = (0..<40).map { i in
            let futureDate = Date().addingTimeInterval(Double(i) * 3 * 3600)
            let futureCondition = conditions.randomElement() ?? .cloudy
            return WeatherForecast(
                date: futureDate,
                temperature: Double.random(in: -20...15),
                condition: futureCondition,
                precipitationProbability: futureCondition.precipitationProbability,
                windSpeed: Double.random(in: 5...60)
            )
        }
    }
    
    // MARK: - Weather Severity
    
    func calculateWeatherSeverity() -> Double {
        guard let weather = currentWeather else { return 0 }
        
        var severity = 0.0
        
        // Wind severity (0-40)
        let windScore = min(weather.windSpeed / 100.0, 0.4) * 100
        severity += windScore
        
        // Precipitation severity (0-30)
        let precipScore = Double(weather.precipitationProbability) / 100.0 * 30
        severity += precipScore
        
        // Visibility severity (0-20)
        let visibilityScore = max(0, (10000 - Double(weather.visibility)) / 10000.0) * 20
        severity += visibilityScore
        
        // Condition multiplier
        switch weather.condition {
        case .storm:
            severity *= 1.5
        case .snow:
            severity *= 1.3
        case .rain:
            severity *= 1.1
        default:
            break
        }
        
        return min(severity, 100)
    }
    
    // Predict if a storm is coming in the next N hours
    func predictStorm(within hours: Int) -> StormPrediction? {
        let relevantForecasts = weatherForecast.filter { forecast in
            let hoursAhead = forecast.date.timeIntervalSince(Date()) / 3600
            return hoursAhead >= 0 && hoursAhead <= Double(hours)
        }
        
        guard !relevantForecasts.isEmpty else { return nil }
        
        // Find worst conditions in the window
        let worstForecast = relevantForecasts.max { a, b in
            a.condition.severity < b.condition.severity
        }
        
        guard let worst = worstForecast, worst.condition.severity >= 0.5 else { return nil }
        
        let avgWindSpeed = relevantForecasts.map { $0.windSpeed }.reduce(0, +) / Double(relevantForecasts.count)
        let maxPrecipProb = relevantForecasts.map { $0.precipitationProbability }.max() ?? 0
        
        return StormPrediction(
            expectedCondition: worst.condition,
            expectedOnset: worst.date,
            confidence: Double(maxPrecipProb) / 100.0,
            predictedWindSpeed: avgWindSpeed,
            impactSeverity: worst.condition.severity
        )
    }
}

// MARK: - Weather Data Models

struct WeatherData {
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let windGust: Double?
    let condition: WeatherCondition
    let description: String
    let icon: String
    let visibility: Int
    let pressure: Int
    let cloudCoverage: Int
    let precipitationProbability: Int
    let location: String
    let timestamp: Date
    
    var temperatureFormatted: String {
        "\(Int(temperature))°C"
    }
    
    var feelsLikeFormatted: String {
        "Feels like \(Int(feelsLike))°C"
    }
    
    var windFormatted: String {
        "\(Int(windSpeed)) km/h"
    }
}

struct WeatherForecast {
    let date: Date
    let temperature: Double
    let condition: WeatherCondition
    let precipitationProbability: Int
    let windSpeed: Double
    
    var hourFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }
    
    var dayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct StormPrediction {
    let expectedCondition: WeatherCondition
    let expectedOnset: Date
    let confidence: Double
    let predictedWindSpeed: Double
    let impactSeverity: Double
    
    var onsetFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: expectedOnset, relativeTo: Date())
    }
    
    var confidencePercentage: Int {
        Int(confidence * 100)
    }
}

enum WeatherCondition: String, Codable {
    case clear = "clear"
    case cloudy = "cloudy"
    case partlyCloudy = "partly_cloudy"
    case rain = "rain"
    case snow = "snow"
    case storm = "storm"
    case fog = "fog"
    case wind = "wind"
    
    var description: String {
        switch self {
        case .clear: return "Clear skies"
        case .cloudy: return "Cloudy"
        case .partlyCloudy: return "Partly cloudy"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .storm: return "Storm"
        case .fog: return "Fog"
        case .wind: return "High winds"
        }
    }
    
    var icon: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .storm: return "cloud.bolt.rain.fill"
        case .fog: return "cloud.fog.fill"
        case .wind: return "wind"
        }
    }
    
    var color: Color {
        switch self {
        case .clear: return .yellow
        case .cloudy: return .gray
        case .partlyCloudy: return .blue
        case .rain: return .blue
        case .snow: return .cyan
        case .storm: return .purple
        case .fog: return .gray
        case .wind: return .teal
        }
    }
    
    var severity: Double {
        switch self {
        case .clear: return 0.0
        case .partlyCloudy: return 0.1
        case .cloudy: return 0.2
        case .fog: return 0.4
        case .rain: return 0.5
        case .wind: return 0.6
        case .snow: return 0.7
        case .storm: return 1.0
        }
    }
    
    var precipitationProbability: Int {
        switch self {
        case .clear, .partlyCloudy: return 0
        case .cloudy: return 20
        case .fog, .wind: return 30
        case .rain: return 80
        case .snow: return 70
        case .storm: return 95
        }
    }
}

enum WeatherError: Error {
    case invalidURL
    case decodingError
    case networkError
}

// MARK: - OpenWeatherMap API Response Models

struct OpenWeatherResponse: Codable {
    let main: MainWeather
    let weather: [WeatherDescription]
    let wind: Wind
    let clouds: Clouds
    let visibility: Int
    let name: String
    let dt: TimeInterval
    
    struct MainWeather: Codable {
        let temp: Double
        let feels_like: Double
        let humidity: Int
        let pressure: Int
    }
    
    struct WeatherDescription: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct Wind: Codable {
        let speed: Double
        let gust: Double?
    }
    
    struct Clouds: Codable {
        let all: Int
    }
}

struct OpenWeatherForecastResponse: Codable {
    let list: [ForecastItem]
    
    struct ForecastItem: Codable {
        let dt: TimeInterval
        let main: OpenWeatherResponse.MainWeather
        let weather: [OpenWeatherResponse.WeatherDescription]
        let wind: OpenWeatherResponse.Wind
        let pop: Double // Probability of precipitation
    }
}

// MARK: - Parsing Extensions

extension WeatherData {
    init(from response: OpenWeatherResponse) {
        self.temperature = response.main.temp
        self.feelsLike = response.main.feels_like
        self.humidity = response.main.humidity
        self.windSpeed = response.wind.speed * 3.6 // Convert m/s to km/h
        self.windGust = response.wind.gust.map { $0 * 3.6 }
        self.condition = WeatherCondition.from(weatherId: response.weather.first?.id ?? 800)
        self.description = response.weather.first?.description.capitalized ?? "Unknown"
        self.icon = response.weather.first?.icon ?? "01d"
        self.visibility = response.visibility
        self.pressure = response.main.pressure
        self.cloudCoverage = response.clouds.all
        self.precipitationProbability = 0
        self.location = response.name
        self.timestamp = Date(timeIntervalSince1970: response.dt)
    }
}

extension WeatherForecast {
    init(from item: OpenWeatherForecastResponse.ForecastItem) {
        self.date = Date(timeIntervalSince1970: item.dt)
        self.temperature = item.main.temp
        self.condition = WeatherCondition.from(weatherId: item.weather.first?.id ?? 800)
        self.precipitationProbability = Int(item.pop * 100)
        self.windSpeed = item.wind.speed * 3.6
    }
}

extension WeatherCondition {
    static func from(weatherId: Int) -> WeatherCondition {
        switch weatherId {
        case 200...232: return .storm    // Thunderstorm
        case 300...321: return .rain     // Drizzle
        case 500...531: return .rain     // Rain
        case 600...622: return .snow     // Snow
        case 700...762: return .fog      // Atmosphere
        case 771, 781: return .wind      // Squall, tornado
        case 800: return .clear          // Clear
        case 801: return .partlyCloudy   // Few clouds
        case 802...804: return .cloudy   // Clouds
        default: return .cloudy
        }
    }
}
