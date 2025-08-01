require 'httparty'

class NominatimGeocodingService
  include HTTParty
  
  BASE_URL = 'https://nominatim.openstreetmap.org'
  
  default_timeout 3
  
  def self.geocode(address)
    response = HTTParty.get("#{BASE_URL}/search", {
      query: {
        q: address,
        format: 'json',
        limit: 1,
        addressdetails: 1
      },
      headers: {
        'User-Agent' => 'WeatherApp/1.0'
      },
      timeout: 3
    })

    if response.success? && response.parsed_response.any?
      location = response.parsed_response.first
      {
        lat: location['lat'].to_f,
        lon: location['lon'].to_f,
        location_name: format_location_name(location)
      }
    else
      nil
    end
  rescue => e
    Rails.logger.error "Nominatim geocoding error: #{e.message}"
    nil
  end

  def self.search_suggestions(query)
    response = HTTParty.get("#{BASE_URL}/search", {
      query: {
        q: query,
        format: 'json',
        limit: 5,
        addressdetails: 1
      },
      headers: {
        'User-Agent' => 'WeatherApp/1.0'
      },
      timeout: 1
    })

    if response.success? && response.parsed_response.any?
      response.parsed_response.map do |location|
        {
          display_name: format_location_name(location),
          full_address: location['display_name']
        }
      end
    else
      []
    end
  rescue => e
    Rails.logger.error "Nominatim search suggestions error: #{e.message}"
    []
  end

  private

  def self.format_location_name(location)
    address = location['address'] || {}
    
    parts = []
    
    city = address['city'] || address['town'] || address['village'] || address['hamlet']
    parts << city if city
    
    state = address['state'] || address['region'] || address['province']
    parts << state if state
    
    parts << address['country'] if address['country']
    
    return location['display_name'] if parts.empty?
    
    parts.join(', ')
  end
end
