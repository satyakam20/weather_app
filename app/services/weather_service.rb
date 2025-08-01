require 'httparty'

class WeatherService
  include HTTParty
  
  WEATHER_URL = 'https://api.open-meteo.com/v1/forecast'

  def get_current_weather(address)
    # creating new cache
    cache_key = "weather_forecast:#{normalize_address_for_cache(address)}"
    
    # get cached data first
    cached_data = Rails.cache.read(cache_key)
    if cached_data
      Rails.logger.info "Weather data served from cache for: #{address}"
      return cached_data.merge(from_cache: true, cached_at: cached_data[:cached_at])
    end

    # fetch fresh data
    Rails.logger.info "Fetching fresh weather data for: #{address}"
    
    coordinates = NominatimGeocodingService.geocode(address)
    return { error: "Could not find location for the given address" } unless coordinates

    weather_data = fetch_weather_data(coordinates[:lat], coordinates[:lon])

    if weather_data
      formatted_data = format_weather_data(weather_data, coordinates[:location_name])
      
      # add cache 
      formatted_data[:from_cache] = false
      formatted_data[:cached_at] = Time.current.iso8601
      
      # cache for 30 minutes
      Rails.cache.write(cache_key, formatted_data, expires_in: 30.minutes)
      Rails.logger.info "Weather data cached for: #{address}"
      
      formatted_data
    else
      { error: "Unable to fetch weather data" }
    end
  rescue => e
    { error: "Weather service error: #{e.message}" }
  end

  private

  def normalize_address_for_cache(address)
    address.to_s.strip.downcase.gsub(/\s+/, '_').gsub(/[^a-z0-9_]/, '')
  end

  def fetch_weather_data(lat, lon)
    response = HTTParty.get(WEATHER_URL, {
      query: {
        latitude: lat,
        longitude: lon,
        current: %w[
          temperature_2m
          relative_humidity_2m
          apparent_temperature
          weather_code
          wind_speed_10m
        ].join(','),
        daily: %w[
          weather_code
          temperature_2m_max
          temperature_2m_min
        ].join(','),
        temperature_unit: 'fahrenheit',
        wind_speed_unit: 'mph',
        precipitation_unit: 'inch',
        timezone: 'auto',
        forecast_days: 7
      }
    })

    response.success? ? response.parsed_response : nil
  end

  def format_weather_data(data, location_name)
    current = data['current']
    daily = data['daily']
    
    today_high = daily['temperature_2m_max'][0]
    today_low = daily['temperature_2m_min'][0]
    
    daily_forecast = []
    (0..4).each do |i|
      next unless daily['time'][i]
      
      date = Date.parse(daily['time'][i])
      daily_forecast << {
        date: date.strftime('%A, %B %d'),
        high: daily['temperature_2m_max'][i].round,
        low: daily['temperature_2m_min'][i].round,
        description: weather_code_to_description(daily['weather_code'][i]),
        icon: weather_code_to_icon(daily['weather_code'][i])
      }
    end

    {
      location: location_name,
      current_temp: current['temperature_2m'].round,
      feels_like: current['apparent_temperature'].round,
      description: weather_code_to_description(current['weather_code']),
      humidity: current['relative_humidity_2m'].round,
      wind_speed: current['wind_speed_10m'].round(1),
      icon: weather_code_to_icon(current['weather_code']),
      today_high: today_high.round,
      today_low: today_low.round,
      daily_forecast: daily_forecast
    }
  end

  WEATHER_DESCRIPTIONS = {
    0 => 'Clear Sky',
    1 => 'Partly Cloudy', 2 => 'Partly Cloudy', 3 => 'Partly Cloudy',
    45 => 'Foggy', 48 => 'Foggy',
    51 => 'Drizzle', 53 => 'Drizzle', 55 => 'Drizzle',
    56 => 'Freezing Drizzle', 57 => 'Freezing Drizzle',
    61 => 'Rain', 63 => 'Rain', 65 => 'Rain',
    66 => 'Freezing Rain', 67 => 'Freezing Rain',
    71 => 'Snow', 73 => 'Snow', 75 => 'Snow',
    77 => 'Snow Grains',
    80 => 'Rain Showers', 81 => 'Rain Showers', 82 => 'Rain Showers',
    85 => 'Snow Showers', 86 => 'Snow Showers',
    95 => 'Thunderstorm',
    96 => 'Thunderstorm with Hail', 99 => 'Thunderstorm with Hail'
  }.freeze

  WEATHER_ICONS = {
    0 => '01d',
    1 => '02d', 2 => '02d',
    3 => '03d',
    45 => '50d', 48 => '50d',
    51 => '09d', 53 => '09d', 55 => '09d', 56 => '09d', 57 => '09d',
    61 => '10d', 63 => '10d', 65 => '10d', 66 => '10d', 67 => '10d',
    71 => '13d', 73 => '13d', 75 => '13d', 77 => '13d',
    80 => '09d', 81 => '09d', 82 => '09d',
    85 => '13d', 86 => '13d',
    95 => '11d', 96 => '11d', 99 => '11d'
  }.freeze

  def weather_code_to_description(code)
    WEATHER_DESCRIPTIONS[code] || 'Unknown'
  end

  def weather_code_to_icon(code)
    WEATHER_ICONS[code] || '01d'
  end
end
