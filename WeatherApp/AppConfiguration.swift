import Foundation

enum AppConfiguration {
    static var weatherAPIKey: String {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "WeatherAPIKey") as? String,
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            rawValue != "SET_YOUR_WEATHERAPI_KEY"
        else {
            return ""
        }

        return rawValue
    }
}
