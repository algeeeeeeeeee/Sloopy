import Foundation
import SwiftUI

struct WeatherHour: Identifiable {
    let time: String
    let temperature: Double
    let precipitationProbability: Int
    let symbol: String

    var id: String { time }
    var hourLabel: String {
        String(time.split(separator: "T").last ?? Substring(time))
    }
}

struct WeatherDay: Identifiable {
    let date: String
    let high: Double
    let low: Double
    let symbol: String

    var id: String { date }
    var dateLabel: String {
        String(date.suffix(5))
    }
}

struct WeatherSnapshot {
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let description: String
    let symbol: String
    let hourly: [WeatherHour]
    let daily: [WeatherDay]
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
        let hourly: Hourly
        let daily: Daily

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

        struct Hourly: Decodable {
            let time: [String]
            let temperature: [Double]
            let precipitationProbability: [Int]
            let code: [Int]

            enum CodingKeys: String, CodingKey {
                case time
                case temperature = "temperature_2m"
                case precipitationProbability = "precipitation_probability"
                case code = "weather_code"
            }
        }

        struct Daily: Decodable {
            let time: [String]
            let high: [Double]
            let low: [Double]
            let code: [Int]

            enum CodingKeys: String, CodingKey {
                case time
                case high = "temperature_2m_max"
                case low = "temperature_2m_min"
                case code = "weather_code"
            }
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
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability,weather_code"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "forecast_days", value: "5"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        let (data, _) = try await URLSession.shared.data(from: forecast.url!)
        let response = try JSONDecoder().decode(ForecastResponse.self, from: data)
        let current = response.current

        let localTimeFormatter = DateFormatter()
        localTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        localTimeFormatter.timeZone = .current
        localTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let currentLocalHour = localTimeFormatter.string(from: Date())

        let upcomingHourIndices = response.hourly.time.indices
            .filter { response.hourly.time[$0] >= currentLocalHour }
            .prefix(8)

        let hours = upcomingHourIndices.compactMap { index -> WeatherHour? in
            guard response.hourly.temperature.indices.contains(index),
                  response.hourly.precipitationProbability.indices.contains(index),
                  response.hourly.code.indices.contains(index) else { return nil }

            return WeatherHour(
                time: response.hourly.time[index],
                temperature: response.hourly.temperature[index],
                precipitationProbability: response.hourly.precipitationProbability[index],
                symbol: weatherSymbol(response.hourly.code[index])
            )
        }

        let days = response.daily.time.indices.compactMap { index -> WeatherDay? in
            guard response.daily.high.indices.contains(index),
                  response.daily.low.indices.contains(index),
                  response.daily.code.indices.contains(index) else { return nil }

            return WeatherDay(
                date: response.daily.time[index],
                high: response.daily.high[index],
                low: response.daily.low[index],
                symbol: weatherSymbol(response.daily.code[index])
            )
        }

        return WeatherSnapshot(
            temperature: current.temperature,
            feelsLike: current.feelsLike,
            humidity: current.humidity,
            windSpeed: current.windSpeed,
            description: weatherDescription(current.code),
            symbol: weatherSymbol(current.code),
            hourly: hours,
            daily: days
        )
    }

    private static func weatherDescription(_ code: Int) -> String {
        switch code {
        case 0: "Clear sky"
        case 1, 2: "Partly cloudy"
        case 3: "Overcast"
        case 45, 48: "Fog"
        case 51...57: "Drizzle"
        case 61...67: "Rain"
        case 71...77: "Snow"
        case 80...82: "Rain showers"
        case 85, 86: "Snow showers"
        case 95...99: "Thunderstorm"
        default: "Weather update"
        }
    }

    private static func weatherSymbol(_ code: Int) -> String {
        switch code {
        case 0: "sun.max.fill"
        case 1, 2: "cloud.sun.fill"
        case 3: "cloud.fill"
        case 45, 48: "cloud.fog.fill"
        case 51...57: "cloud.drizzle.fill"
        case 61...67: "cloud.rain.fill"
        case 71...77: "snowflake"
        case 80...82: "cloud.heavyrain.fill"
        case 85, 86: "cloud.snow.fill"
        case 95...99: "cloud.bolt.rain.fill"
        default: "cloud.sun.fill"
        }
    }
}

struct NativeWeatherCard: View {
    @AppStorage("sloopy-native-weather-location")
    private var city = "Pontianak"

    @State private var weather: WeatherSnapshot?
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var isExpanded = false

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
                        .font(.caption.weight(.semibold))
                }
                .disabled(loading)

                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Label(
                        isExpanded ? "Less" : "Details",
                        systemImage: isExpanded ? "chevron.up" : "chevron.down"
                    )
                    .font(.caption.weight(.semibold))
                }
                .disabled(weather == nil)
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

            if isExpanded, let weather {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("NEXT HOURS")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(weather.hourly) { hour in
                                VStack(spacing: 7) {
                                    Text(hour.hourLabel)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                    Image(systemName: hour.symbol)
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.accentColor)
                                    Text("\(Int(hour.temperature.rounded()))°")
                                        .font(.subheadline.weight(.bold))
                                    Label("\(hour.precipitationProbability)%", systemImage: "drop.fill")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 58)
                                .padding(.vertical, 10)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
                            }
                        }
                    }

                    Text("5-DAY OUTLOOK")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                        .padding(.top, 3)

                    HStack(spacing: 7) {
                        ForEach(weather.daily) { day in
                            VStack(spacing: 7) {
                                Text(day.dateLabel)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                Image(systemName: day.symbol)
                                    .font(.system(size: 17))
                                    .foregroundStyle(Color.accentColor)
                                Text("\(Int(day.high.rounded()))°")
                                    .font(.caption.weight(.bold))
                                Text("\(Int(day.low.rounded()))°")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

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
