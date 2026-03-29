import SwiftUI

struct WeatherDashboardView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = WeatherDashboardViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let weather = viewModel.weather {
                    WeatherDetailsView(weather: weather, isLoading: viewModel.isLoading) {
                        locationManager.refreshLocation()
                    }
                } else if viewModel.isLoading {
                    ProgressView("Wetterdaten werden geladen ...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView(
                        "Standortwetter",
                        systemImage: "cloud.sun",
                        description: Text(viewModel.errorMessage ?? locationManager.errorMessage ?? "Erlaube den Standortzugriff, um aktuelle Wetterdaten und die 7-Tage-Prognose für deinen Standort zu laden.")
                    )
                }
            }
            .navigationTitle("Mein Standort")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Aktualisieren") {
                        locationManager.refreshLocation()
                    }
                }
            }
            .task {
                locationManager.requestLocationAccess()
            }
            .onChange(of: locationManager.currentLocation) { _, location in
                guard let location else { return }
                Task {
                    await viewModel.loadWeather(for: location)
                }
            }
            .onChange(of: locationManager.errorMessage) { _, message in
                if let message {
                    viewModel.errorMessage = message
                }
            }
        }
    }
}

struct WeatherDetailsView: View {
    let weather: WeatherResponse
    let isLoading: Bool
    let onRefresh: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                currentHeader
                detailsGrid
                astronomyCard
                airQualityCard
                alertsSection
                forecastSection
            }
            .padding()
        }
        .refreshable {
            onRefresh()
        }
        .overlay(alignment: .top) {
            if isLoading {
                ProgressView()
                    .padding(.top, 8)
            }
        }
    }

    // Formats a Double (optional) to one decimal place, falling back to "n/a" for nil
    private func oneDecimal(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return String(format: "%.1f", value)
    }

    private var currentHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(weather.location.name)
                .font(.largeTitle.bold())
            Text([weather.location.region, weather.location.country].filter { !$0.isEmpty }.joined(separator: ", "))
                .foregroundStyle(.secondary)
            HStack(alignment: .top) {
                AsyncImage(url: iconURL(from: weather.current.condition.icon)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(weather.current.tempC.rounded())) °C")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text(weather.current.condition.text)
                        .font(.title3)
                    Text("Gefühlt wie \(Int(weather.current.feelslikeC.rounded())) °C")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let today = weather.forecast.forecastday.first {
                HStack {
                    Label("Max. \(Int(today.day.maxtempC.rounded())) °C", systemImage: "thermometer.high")
                    Spacer()
                    Label("Min. \(Int(today.day.mintempC.rounded())) °C", systemImage: "thermometer.low")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            WeatherMetricCard(title: "Wind", value: "\(Int(weather.current.windKph.rounded())) km/h", subtitle: weather.current.windDir, systemImage: "wind")
            WeatherMetricCard(title: "Böen", value: "\(Int(weather.current.gustKph.rounded())) km/h", subtitle: "Maximal", systemImage: "tornado")
            WeatherMetricCard(title: "Luftfeuchte", value: "\(weather.current.humidity) %", subtitle: "Relativ", systemImage: "humidity")
            WeatherMetricCard(title: "Niederschlag", value: "\(oneDecimal(weather.current.precipMm)) mm", subtitle: "Aktuell", systemImage: "cloud.rain")
            WeatherMetricCard(title: "Sichtweite", value: "\(oneDecimal(weather.current.visKm)) km", subtitle: "Aktuell", systemImage: "eye")
            WeatherMetricCard(title: "Luftdruck", value: "\(Int(weather.current.pressureMb.rounded())) hPa", subtitle: "Meereshöhe", systemImage: "gauge")
            WeatherMetricCard(title: "UV-Index", value: String(format: "%.1f", weather.current.uv), subtitle: "Aktuell", systemImage: "sun.max")
            WeatherMetricCard(title: "Bewölkung", value: "\(weather.current.cloud) %", subtitle: "Bedeckung", systemImage: "cloud")
        }
    }

    private var astronomyCard: some View {
        Group {
            if let today = weather.forecast.forecastday.first {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Astronomie")
                        .font(.headline)
                    HStack {
                        WeatherMetricLine(label: "Sonnenaufgang", value: today.astro.sunrise)
                        Spacer()
                        WeatherMetricLine(label: "Sonnenuntergang", value: today.astro.sunset)
                    }
                    HStack {
                        WeatherMetricLine(label: "Mondphase", value: today.astro.moonPhase)
                        Spacer()
                        WeatherMetricLine(label: "Mondlicht", value: "\(today.astro.moonIllumination) %")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var airQualityCard: some View {
        Group {
            if let air = weather.current.airQuality {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Luftqualität")
                        .font(.headline)
                    Text(air.epaLabel)
                        .font(.title3.bold())
                    Divider()
                    HStack {
                        WeatherMetricLine(label: "PM2.5", value: oneDecimal(air.pm2_5))
                        Spacer()
                        WeatherMetricLine(label: "PM10", value: oneDecimal(air.pm10))
                    }
                    HStack {
                        WeatherMetricLine(label: "Ozon", value: oneDecimal(air.o3))
                        Spacer()
                        WeatherMetricLine(label: "NO₂", value: oneDecimal(air.no2))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var alertsSection: some View {
        Group {
            if let alerts = weather.alerts?.alert, !alerts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Warnungen")
                        .font(.headline)
                    ForEach(alerts) { alert in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(alert.headline)
                                .font(.subheadline.bold())
                            Text("\(alert.event) · \(alert.severity) · \(alert.urgency)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(alert.desc)
                                .font(.subheadline)
                            if let instruction = alert.instruction, !instruction.isEmpty {
                                Text(instruction)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
    }

    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(weather.forecast.forecastday.count)-Tage-Prognose")
                .font(.headline)

            ForEach(weather.forecast.forecastday) { day in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate(day.date))
                                .font(.headline)
                            Text(day.day.condition.text)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        AsyncImage(url: iconURL(from: day.day.condition.icon)) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                    }

                    HStack {
                        WeatherMetricLine(label: "Min/Max", value: "\(Int(day.day.mintempC.rounded())) / \(Int(day.day.maxtempC.rounded())) °C")
                        Spacer()
                        WeatherMetricLine(label: "Regen", value: "\(day.day.dailyChanceOfRain ?? 0) %")
                    }

                    HStack {
                        WeatherMetricLine(label: "Wind", value: "\(Int(day.day.maxwindKph.rounded())) km/h")
                        Spacer()
                        WeatherMetricLine(label: "Niederschlag", value: "\(oneDecimal(day.day.totalprecipMm)) mm")
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(sampleHours(for: day)) { hour in
                                VStack(spacing: 6) {
                                    Text(hourLabel(from: hour.time))
                                        .font(.caption)
                                    AsyncImage(url: iconURL(from: hour.condition.icon)) { image in
                                        image.resizable().scaledToFit()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 26, height: 26)
                                    Text("\(Int(hour.tempC.rounded())) °")
                                        .font(.caption.bold())
                                    Text("\(hour.chanceOfRain ?? 0) %")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 52)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func iconURL(from path: String) -> URL? {
        URL(string: path.hasPrefix("//") ? "https:\(path)" : path)
    }

    private func formattedDate(_ value: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "de_DE")
        guard let date = formatter.date(from: value) else { return value }
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: date)
    }

    private func hourLabel(from value: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "de_DE")
        guard let date = formatter.date(from: value) else { return value }
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func sampleHours(for day: ForecastDay) -> [HourWeather] {
        day.hour.enumerated().compactMap { index, hour in
            index.isMultiple(of: 6) ? hour : nil
        }
    }
}

private struct WeatherMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct WeatherMetricLine: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
