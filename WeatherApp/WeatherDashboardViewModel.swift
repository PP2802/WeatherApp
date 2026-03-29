import CoreLocation
import Foundation

@MainActor
final class WeatherDashboardViewModel: ObservableObject {
    @Published var weather: WeatherResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [SearchLocation] = []

    private let service: WeatherAPIService
    private var searchTask: Task<Void, Never>?

    init(service: WeatherAPIService = WeatherAPIService()) {
        self.service = service
    }

    func loadWeather(for query: WeatherQuery) async {
        isLoading = true
        errorMessage = nil

        do {
            weather = try await service.fetchWeather(for: query)
        } catch {
            weather = nil
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadWeather(for location: CLLocation) async {
        await loadWeather(for: .coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
    }

    func searchCities(text: String) {
        searchTask?.cancel()

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.count >= 2 else {
            searchResults = []
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            do {
                let results = try await self?.service.searchLocations(query: trimmedText) ?? []
                guard !Task.isCancelled else { return }
                self?.searchResults = results
            } catch {
                guard !Task.isCancelled else { return }
                self?.searchResults = []
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func clearSearchResults() {
        searchTask?.cancel()
        searchResults = []
    }
}
