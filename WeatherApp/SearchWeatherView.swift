import SwiftUI

struct SearchWeatherView: View {
    @StateObject private var viewModel = WeatherDashboardViewModel()
    @State private var searchText = ""
    @State private var selectedLocationName = ""

    var body: some View {
        NavigationStack {
            Group {
                if let weather = viewModel.weather {
                    WeatherDetailsView(weather: weather, isLoading: viewModel.isLoading) {
                        Task {
                            guard !selectedLocationName.isEmpty else { return }
                            await viewModel.loadWeather(for: .city(selectedLocationName))
                        }
                    }
                } else if viewModel.isLoading {
                    ProgressView("Wetterdaten werden geladen ...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView(
                        "Stadtsuche",
                        systemImage: "magnifyingglass.circle",
                        description: Text(viewModel.errorMessage ?? "Suche nach einer Stadt, um aktuelle Wetterdaten und die 7-Tage-Prognose anzuzeigen.")
                    )
                }
            }
            .navigationTitle("Stadtsuche")
            .searchable(text: $searchText, prompt: "Stadt eingeben")
            .onSubmit(of: .search) {
                submitSearch()
            }
            .onChange(of: searchText) { _, newValue in
                viewModel.errorMessage = nil
                viewModel.searchCities(text: newValue)
            }
            .overlay(alignment: .top) {
                if !viewModel.searchResults.isEmpty {
                    SearchSuggestionList(results: viewModel.searchResults) { location in
                        searchText = location.displayName
                        selectedLocationName = location.displayName
                        viewModel.clearSearchResults()
                        Task {
                            await viewModel.loadWeather(for: .city(location.displayName))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Suchen") {
                        submitSearch()
                    }
                }
            }
        }
    }

    private func submitSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selectedLocationName = trimmed
        viewModel.clearSearchResults()
        Task {
            await viewModel.loadWeather(for: .city(trimmed))
        }
    }
}

private struct SearchSuggestionList: View {
    let results: [SearchLocation]
    let onSelect: (SearchLocation) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(results.prefix(6)) { location in
                Button {
                    onSelect(location)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.name)
                            .foregroundStyle(.primary)
                        Text([location.region, location.country].filter { !$0.isEmpty }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                }

                if location.id != results.prefix(6).last?.id {
                    Divider()
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
