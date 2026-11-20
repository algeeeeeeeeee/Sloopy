
import Foundation
import SwiftUI

struct WeatherSnapshot {
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let description: String
    let symbol: String
}

enum WeatherService {
    private struct GeoResponse: Decodable {
        let results: [GeoPlace]?
    }

    private struct GeoPlace: Decodable {
        let latitude: Double
        let longitude: Double
    }

    private struct ForecastResponse: Decodable {
        let current: Current

        struct Current: Decodable {
            let temperature: Double
            let feelsLike: Double
            let humidity: Int
            let windSpeed: Double
            let code: Int

            enum CodingKeys: String, CodingKey {
                case temperature = "temperature_2m"
                case feelsLike = "apparent_temperature"
                case humidity = "relative_humidity_2m"
                case windSpeed = "wind_speed_10m"
                case code = "weather_code"
            }
        }

        enum CodingKeys: String, CodingKey {
            case current
        }
    }

    static func fetch(city: String) async throws -> WeatherSnapshot {
        var geo = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        geo.queryItems = [
            URLQueryItem(name: "name", value: city),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "countryCode", value: "ID")
        ]

        let (geoData, _) = try await URLSession.shared.data(from: geo.url!)
        let place = try JSONDecoder().decode(GeoResponse.self, from: geoData)
        guard let result = place.results?.first else {
            throw URLError(.cannotFindHost)
        }

        var forecast = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        forecast.queryItems = [
            URLQueryItem(name: "latitude", value: "\(result.latitude)"),
            URLQueryItem(name: "longitude", value: "\(result.longitude)"),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        let (data, _) = try await URLSession.shared.data(from: forecast.url!)
        let response = try JSONDecoder().decode(ForecastResponse.self, from: data)
        let current = response.current

        let (description, symbol) = weatherDescription(current.code)

        return WeatherSnapshot(
            temperature: current.temperature,
            feelsLike: current.feelsLike,
            humidity: current.humidity,
            windSpeed: current.windSpeed,
            description: description,
            symbol: symbol
        )
    }

    private static func weatherDescription(_ code: Int) -> (String, String) {
        switch code {
        case 0: ("Clear sky", "sun.max.fill")
        case 1, 2: ("Partly cloudy", "cloud.sun.fill")
        case 3: ("Overcast", "cloud.fill")
        case 45, 48: ("Fog", "cloud.fog.fill")
        case 51...57: ("Drizzle", "cloud.drizzle.fill")
        case 61...67: ("Rain", "cloud.rain.fill")
        case 71...77: ("Snow", "snowflake")
        case 80...82: ("Rain showers", "cloud.heavyrain.fill")
        case 85, 86: ("Snow showers", "cloud.snow.fill")
        case 95...99: ("Thunderstorm", "cloud.bolt.rain.fill")
        default: ("Weather update", "cloud.sun.fill")
        }
    }
}

struct NativeWeatherCard: View {
    @AppStorage("sloopy-native-weather-location")
    private var city = "Pontianak"

    @State private var weather: WeatherSnapshot?
    @State private var loading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label("LOCAL WEATHER", systemImage: "location.fill")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)

                Spacer()

                Button {
                    Task { await refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(loading)
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 13) {
                if loading && weather == nil {
                    ProgressView()
                        .frame(width: 48, height: 48)
                } else if let weather {
                    Image(systemName: weather.symbol)
                        .font(.system(size: 32))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(Int(weather.temperature.rounded()))°")
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                            .monospacedDigit()

                        Text(weather.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 5) {
                        Text("Feels \(Int(weather.feelsLike.rounded()))°")
                        Text("Humidity \(weather.humidity)%")
                        Text("Wind \(Int(weather.windSpeed.rounded())) km/h")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(city).font(.headline)
                        Text(errorMessage ?? "Getting forecast…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(minHeight: 55)

            HStack {
                Text(city)
                Spacer()
                Text("Powered by Open-Meteo")
            }
            .font(.system(size: 9))
            .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 21))
        .task(id: city) {
            await refresh()
        }
    }

    @MainActor
    private func refresh() async {
        guard !city.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        loading = true
        errorMessage = nil

        do {
            weather = try await WeatherService.fetch(city: city)
        } catch {
            errorMessage = "Forecast unavailable. Tap refresh."
        }

        loading = false
    }
}
