import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WeatherDashboardView()
                .tabItem {
                    Label("Mein Standort", systemImage: "location.fill")
                }

            SearchWeatherView()
                .tabItem {
                    Label("Stadtsuche", systemImage: "magnifyingglass")
                }
        }
    }
}

#Preview {
    ContentView()
}
