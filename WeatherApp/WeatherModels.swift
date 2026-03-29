import Foundation

struct WeatherResponse: Decodable {
    let location: Location
    let current: CurrentWeather
    let forecast: Forecast
    let alerts: AlertsContainer?
}

struct Location: Decodable {
    let name: String
    let region: String
    let country: String
    let localtime: String
}

struct CurrentWeather: Decodable {
    let lastUpdatedEpoch: Int
    let tempC: Double
    let feelslikeC: Double
    let windKph: Double
    let gustKph: Double
    let windDir: String
    let pressureMb: Double
    let precipMm: Double
    let humidity: Int
    let cloud: Int
    let visKm: Double
    let uv: Double
    let condition: WeatherCondition
    let airQuality: AirQuality?

    enum CodingKeys: String, CodingKey {
        case lastUpdatedEpoch = "last_updated_epoch"
        case tempC = "temp_c"
        case feelslikeC = "feelslike_c"
        case windKph = "wind_kph"
        case gustKph = "gust_kph"
        case windDir = "wind_dir"
        case pressureMb = "pressure_mb"
        case precipMm = "precip_mm"
        case humidity
        case cloud
        case visKm = "vis_km"
        case uv
        case condition
        case airQuality = "air_quality"
    }
}

struct WeatherCondition: Decodable {
    let text: String
    let icon: String
}

struct AirQuality: Decodable {
    let co: Double?
    let no2: Double?
    let o3: Double?
    let so2: Double?
    let pm2_5: Double?
    let pm10: Double?
    let usEpaIndex: Int?

    enum CodingKeys: String, CodingKey {
        case co, no2, o3, so2, pm10
        case pm2_5 = "pm2_5"
        case usEpaIndex = "us-epa-index"
    }
}

struct Forecast: Decodable {
    let forecastday: [ForecastDay]
}

struct ForecastDay: Decodable, Identifiable {
    let date: String
    let day: DaySummary
    let astro: Astro
    let hour: [HourWeather]

    var id: String { date }
}

struct DaySummary: Decodable {
    let maxtempC: Double
    let mintempC: Double
    let avgtempC: Double
    let maxwindKph: Double
    let totalprecipMm: Double
    let totalsnowCm: Double
    let avgvisKm: Double
    let avghumidity: Int
    let dailyChanceOfRain: Int?
    let dailyChanceOfSnow: Int?
    let condition: WeatherCondition
    let uv: Double

    enum CodingKeys: String, CodingKey {
        case maxtempC = "maxtemp_c"
        case mintempC = "mintemp_c"
        case avgtempC = "avgtemp_c"
        case maxwindKph = "maxwind_kph"
        case totalprecipMm = "totalprecip_mm"
        case totalsnowCm = "totalsnow_cm"
        case avgvisKm = "avgvis_km"
        case avghumidity
        case dailyChanceOfRain = "daily_chance_of_rain"
        case dailyChanceOfSnow = "daily_chance_of_snow"
        case condition
        case uv
    }
}

struct Astro: Decodable {
    let sunrise: String
    let sunset: String
    let moonrise: String
    let moonset: String
    let moonPhase: String
    let moonIllumination: Int

    enum CodingKeys: String, CodingKey {
        case sunrise, sunset, moonrise, moonset
        case moonPhase = "moon_phase"
        case moonIllumination = "moon_illumination"
    }
}

struct HourWeather: Decodable, Identifiable {
    let timeEpoch: Int
    let time: String
    let tempC: Double
    let condition: WeatherCondition
    let chanceOfRain: Int?
    let chanceOfSnow: Int?
    let windKph: Double

    var id: Int { timeEpoch }

    enum CodingKeys: String, CodingKey {
        case timeEpoch = "time_epoch"
        case time
        case tempC = "temp_c"
        case condition
        case chanceOfRain = "chance_of_rain"
        case chanceOfSnow = "chance_of_snow"
        case windKph = "wind_kph"
    }
}

struct WeatherAlert: Decodable, Identifiable {
    let headline: String
    let severity: String
    let urgency: String
    let event: String
    let desc: String
    let instruction: String?
    let effective: String
    let expires: String

    var id: String { headline + effective }
}

struct AlertsContainer: Decodable {
    let alert: [WeatherAlert]
}

struct SearchLocation: Decodable, Identifiable {
    let id = UUID()
    let name: String
    let region: String
    let country: String
    let lat: Double
    let lon: Double

    private enum CodingKeys: String, CodingKey {
        case name, region, country, lat, lon
    }

    var displayName: String {
        [name, region, country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

enum WeatherQuery: Equatable {
    case coordinates(latitude: Double, longitude: Double)
    case city(String)

    var apiValue: String {
        switch self {
        case let .coordinates(latitude, longitude):
            return "\(latitude),\(longitude)"
        case let .city(city):
            return city
        }
    }
}

extension AirQuality {
    var epaLabel: String {
        switch usEpaIndex ?? 0 {
        case 1:
            return "Gut"
        case 2:
            return "Mäßig"
        case 3:
            return "Belastet für sensible Gruppen"
        case 4:
            return "Ungesund"
        case 5:
            return "Sehr ungesund"
        case 6:
            return "Gefährlich"
        default:
            return "Keine Angabe"
        }
    }
}
