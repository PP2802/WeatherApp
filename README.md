# WeatherApp

Eine deutschsprachige iOS-Wetter-App in SwiftUI mit WeatherAPI.

## Funktionen

- Aktuelles Wetter für den aktuellen Standort
- Aktuelles Wetter für per Städtenamen gesuchte Orte
- 7-Tage-Prognose für aktuellen Standort und Suchorte
- Deutsche Wettertexte über `lang=de`
- Umfangreiche Wetterdetails inklusive Luftqualität, Astronomie und Warnungen

## Technik

- SwiftUI
- CoreLocation für den aktuellen Standort
- WeatherAPI `forecast.json` für aktuelle Wetterdaten plus 7-Tage-Prognose
- WeatherAPI `search.json` für die Stadtsuche

## Projektstruktur

- `WeatherApp.xcodeproj`: Xcode-Projekt
- `WeatherApp/WeatherAPIService.swift`: API-Anbindung
- `WeatherApp/LocationManager.swift`: Standortzugriff
- `WeatherApp/WeatherDashboardViewModel.swift`: Lade- und Suchlogik
- `WeatherApp/WeatherDashboardView.swift`: Wetteransicht für aktuellen Standort
- `WeatherApp/SearchWeatherView.swift`: Suche und Wetteransicht für Städte

## Einrichtung

1. Projekt in Xcode öffnen:

```bash
open WeatherApp.xcodeproj
```

2. In `WeatherApp/Info.plist` den Platzhalterwert von `WeatherAPIKey` auf deinen echten Key setzen.

```xml
<key>WeatherAPIKey</key>
<string>DEIN_KEY</string>
```

3. Ein iPhone-Simulator- oder Geräte-Target wählen und die App starten.

## API-Endpunkte

- Aktueller Standort oder Stadtwetter mit 7 Tagen:

```text
https://api.weatherapi.com/v1/forecast.json?key=DEIN_KEY&q=LAT,LON&days=7&aqi=yes&alerts=yes&lang=de
```

```text
https://api.weatherapi.com/v1/forecast.json?key=DEIN_KEY&q=Berlin&days=7&aqi=yes&alerts=yes&lang=de
```

- Stadtsuche:

```text
https://api.weatherapi.com/v1/search.json?key=DEIN_KEY&q=Berlin
```

## Hinweise

- Für den Standortzugriff ist die iOS-Berechtigung "Beim Verwenden der App" hinterlegt.
- Die App zeigt stündliche Stichproben innerhalb der Tagesprognose an.
- Falls kein API-Key hinterlegt ist, erscheint eine verständliche Fehlermeldung in der Oberfläche.


Zur Weiterbearbeitung der App in Codex:
codex resume 019d3a0b-2542-7e10-9a31-1a959b9a6443


