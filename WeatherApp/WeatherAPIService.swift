import Foundation

enum WeatherServiceError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Bitte trage zuerst deinen WeatherAPI-Key in der Info.plist ein."
        case .invalidURL:
            return "Die Wetteranfrage konnte nicht erstellt werden."
        case .invalidResponse:
            return "Die Wetterdaten konnten nicht gelesen werden."
        case let .requestFailed(message):
            return message
        }
    }
}

struct WeatherAPIErrorResponse: Decodable {
    let error: WeatherAPIMessage
}

struct WeatherAPIMessage: Decodable {
    let message: String
}

final class WeatherAPIService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchWeather(for query: WeatherQuery, days: Int = 7) async throws -> WeatherResponse {
        guard !AppConfiguration.weatherAPIKey.isEmpty else {
            throw WeatherServiceError.missingAPIKey
        }

        var components = URLComponents(string: "https://api.weatherapi.com/v1/forecast.json")
        components?.queryItems = [
            URLQueryItem(name: "key", value: AppConfiguration.weatherAPIKey),
            URLQueryItem(name: "q", value: query.apiValue),
            URLQueryItem(name: "days", value: String(days)),
            URLQueryItem(name: "aqi", value: "yes"),
            URLQueryItem(name: "alerts", value: "yes"),
            URLQueryItem(name: "lang", value: "de")
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validate(response: response, data: data)
        return try decoder.decode(WeatherResponse.self, from: data)
    }

    func searchLocations(query: String) async throws -> [SearchLocation] {
        guard !AppConfiguration.weatherAPIKey.isEmpty else {
            throw WeatherServiceError.missingAPIKey
        }

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        var components = URLComponents(string: "https://api.weatherapi.com/v1/search.json")
        components?.queryItems = [
            URLQueryItem(name: "key", value: AppConfiguration.weatherAPIKey),
            URLQueryItem(name: "q", value: query)
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validate(response: response, data: data)
        return try decoder.decode([SearchLocation].self, from: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherServiceError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let message = (try? decoder.decode(WeatherAPIErrorResponse.self, from: data).error.message)
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw WeatherServiceError.requestFailed(message)
        }
    }
}
