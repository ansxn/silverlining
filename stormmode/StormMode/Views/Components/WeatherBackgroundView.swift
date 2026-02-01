import SwiftUI

// MARK: - Weather Background View
// Dynamic background that changes based on real-time weather conditions

struct WeatherBackgroundView: View {
    @ObservedObject var weatherService = WeatherService.shared
    @ObservedObject var dataService = MockDataService.shared
    
    var body: some View {
        ZStack {
            // Base gradient
            backgroundGradient
                .ignoresSafeArea()
            
            // Weather particles overlay
            if shouldShowParticles {
                WeatherParticlesView(condition: effectiveCondition)
                    .ignoresSafeArea()
            }
            
            // Storm mode overlay
            if dataService.stormState.isStormMode {
                StormModeOverlay()
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 1.0), value: effectiveCondition)
        .onAppear {
            // Request location permission to enable live weather
            weatherService.requestLocationPermission()
        }
    }
    
    private var effectiveCondition: WeatherCondition {
        weatherService.currentWeather?.condition ?? .cloudy
    }
    
    private var shouldShowParticles: Bool {
        switch effectiveCondition {
        case .rain, .snow, .storm:
            return true
        default:
            return dataService.stormState.isStormMode
        }
    }
    
    private var backgroundGradient: LinearGradient {
        if dataService.stormState.isStormMode {
            return stormModeGradient
        }
        
        switch effectiveCondition {
        case .clear:
            return clearSkyGradient
        case .partlyCloudy:
            return partlyCloudyGradient
        case .cloudy:
            return cloudyGradient
        case .rain:
            return rainyGradient
        case .snow:
            return snowyGradient
        case .storm:
            return stormGradient
        case .fog:
            return foggyGradient
        case .wind:
            return windyGradient
        }
    }
    
    // MARK: - Gradient Definitions
    
    private var clearSkyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.53, green: 0.81, blue: 0.92), // Light sky blue
                Color(red: 0.93, green: 0.96, blue: 0.98)  // Near white
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var partlyCloudyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.60, green: 0.78, blue: 0.90),
                Color(red: 0.90, green: 0.93, blue: 0.96)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var cloudyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.70, green: 0.75, blue: 0.80),
                Color(red: 0.88, green: 0.90, blue: 0.92)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var rainyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.55, blue: 0.65),
                Color(red: 0.75, green: 0.80, blue: 0.85)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var snowyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.80, green: 0.85, blue: 0.90),
                Color(red: 0.95, green: 0.96, blue: 0.98)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var stormGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.25, green: 0.30, blue: 0.40),
                Color(red: 0.50, green: 0.55, blue: 0.60)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var stormModeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.30, green: 0.25, blue: 0.45), // Deep purple
                Color(red: 0.45, green: 0.40, blue: 0.55)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var foggyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.80, green: 0.82, blue: 0.84),
                Color(red: 0.92, green: 0.93, blue: 0.94)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var windyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.55, green: 0.70, blue: 0.80),
                Color(red: 0.85, green: 0.90, blue: 0.93)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Weather Particles View

struct WeatherParticlesView: View {
    let condition: WeatherCondition
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                drawParticles(context: context, size: size, date: timeline.date)
            }
        }
    }
    
    private func drawParticles(context: GraphicsContext, size: CGSize, date: Date) {
        let seconds = date.timeIntervalSinceReferenceDate
        let particleCount = particleCountForCondition
        
        for i in 0..<particleCount {
            let seed = Double(i) * 12345.6789
            let x = ((sin(seed) + 1) / 2) * size.width
            let baseY = (seconds * fallSpeed + seed).truncatingRemainder(dividingBy: size.height + 50)
            let y = baseY - 50
            
            // Add horizontal drift for wind/storm
            let drift: CGFloat
            if condition == .storm || condition == .wind {
                drift = CGFloat(sin(seconds * 2 + seed) * 30)
            } else {
                drift = CGFloat(sin(seed) * 5)
            }
            
            let adjustedX = x + drift
            
            drawParticle(context: context, x: adjustedX, y: y, index: i)
        }
    }
    
    private func drawParticle(context: GraphicsContext, x: CGFloat, y: CGFloat, index: Int) {
        switch condition {
        case .rain, .storm:
            // Rain drops - elongated
            let length: CGFloat = condition == .storm ? 15 : 10
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x - 2, y: y + length))
            context.stroke(path, with: .color(.white.opacity(0.4)), lineWidth: 1.5)
            
        case .snow:
            // Snowflakes - small circles
            let size: CGFloat = CGFloat.random(in: 2...5)
            let rect = CGRect(x: x - size/2, y: y - size/2, width: size, height: size)
            context.fill(Circle().path(in: rect), with: .color(.white.opacity(0.7)))
            
        default:
            break
        }
    }
    
    private var particleCountForCondition: Int {
        switch condition {
        case .storm: return 150
        case .rain: return 100
        case .snow: return 80
        default: return 0
        }
    }
    
    private var fallSpeed: Double {
        switch condition {
        case .storm: return 800
        case .rain: return 500
        case .snow: return 100
        default: return 200
        }
    }
}

// MARK: - Storm Mode Overlay

struct StormModeOverlay: View {
    @State private var lightningFlash = false
    @State private var pulseOpacity = 0.0
    
    var body: some View {
        ZStack {
            // Subtle pulse effect
            Color.stormActive.opacity(pulseOpacity * 0.1)
            
            // Occasional lightning flash
            if lightningFlash {
                Color.white.opacity(0.3)
            }
        }
        .onAppear {
            startPulseAnimation()
            startLightningAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseOpacity = 1.0
        }
    }
    
    private func startLightningAnimation() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 5...15), repeats: true) { _ in
            triggerLightning()
        }
    }
    
    private func triggerLightning() {
        withAnimation(.easeIn(duration: 0.1)) {
            lightningFlash = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                lightningFlash = false
            }
        }
    }
}

// MARK: - Weather Status Bar

struct WeatherStatusBar: View {
    @ObservedObject var weatherService = WeatherService.shared
    
    var body: some View {
        if let weather = weatherService.currentWeather {
            HStack(spacing: 12) {
                // Weather icon
                Image(systemName: weather.condition.icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .symbolEffect(.variableColor.iterative, options: .repeating, value: weather.condition == .storm)
                
                // Temperature
                Text(weather.temperatureFormatted)
                    .font(.stormHeadline)
                    .foregroundColor(.textPrimary)
                
                // Condition
                Text(weather.description)
                    .font(.stormCaption)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                // Wind indicator for high winds
                if weather.windSpeed > 30 {
                    HStack(spacing: 4) {
                        Image(systemName: "wind")
                            .font(.caption)
                        Text(weather.windFormatted)
                            .font(.stormFootnote)
                    }
                    .foregroundColor(.statusWarning)
                }
                
                // Location
                Text(weather.location)
                    .font(.stormFootnote)
                    .foregroundColor(.textLight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        } else if weatherService.isDemoMode {
            DemoWeatherBadge()
        }
    }
    
    private var iconColor: Color {
        weatherService.currentWeather?.condition.color ?? .gray
    }
}

// MARK: - Demo Weather Badge

struct DemoWeatherBadge: View {
    @ObservedObject var weatherService = WeatherService.shared
    
    var body: some View {
        Button(action: { weatherService.loadDemoWeather() }) {
            HStack(spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .font(.caption)
                Text("Tap for demo weather")
                    .font(.stormFootnote)
            }
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cardYellow.opacity(0.3))
            )
        }
    }
}

// MARK: - Weather Forecast Strip

struct WeatherForecastStrip: View {
    @ObservedObject var weatherService = WeatherService.shared
    
    // Show next 8 forecast entries (24 hours)
    private var upcomingForecasts: [WeatherForecast] {
        Array(weatherService.weatherForecast.prefix(8))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Forecast")
                .font(.stormHeadline)
                .foregroundColor(.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(upcomingForecasts.indices, id: \.self) { index in
                        ForecastHourCard(forecast: upcomingForecasts[index])
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
        .cardShadow()
    }
}

struct ForecastHourCard: View {
    let forecast: WeatherForecast
    
    var body: some View {
        VStack(spacing: 8) {
            Text(forecast.hourFormatted)
                .font(.stormFootnote)
                .foregroundColor(.textSecondary)
            
            Image(systemName: forecast.condition.icon)
                .font(.title2)
                .foregroundColor(forecast.condition.color)
            
            Text("\(Int(forecast.temperature))°")
                .font(.stormBodyBold)
                .foregroundColor(.textPrimary)
            
            if forecast.precipitationProbability > 20 {
                Text("\(forecast.precipitationProbability)%")
                    .font(.stormFootnote)
                    .foregroundColor(.cardBlue)
            }
        }
        .frame(width: 60)
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        WeatherBackgroundView()
        
        VStack {
            WeatherStatusBar()
                .padding()
            
            Spacer()
            
            WeatherForecastStrip()
                .padding()
        }
    }
}
