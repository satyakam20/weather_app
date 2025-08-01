require 'rails_helper'

RSpec.describe WeatherService, type: :service do
  let(:service) { WeatherService.new }
  let(:address) { 'Vancouver, BC' }

  describe '#get_current_weather' do
    context 'when address is valid', :vcr do
      it 'returns weather data with required fields' do
        result = service.get_current_weather(address)

        expect(result).to be_a(Hash)
        expect(result).to include(:location, :current_temp, :description)
        expect(result[:location]).to be_present
        expect(result[:current_temp]).to be_a(Numeric)
        expect(result[:description]).to be_present
      end

      it 'includes cache metadata' do
        result = service.get_current_weather(address)

        expect(result).to include(:from_cache, :cached_at)
        expect(result[:from_cache]).to be_in([true, false])
        expect(result[:cached_at]).to be_present
      end

      it 'includes forecast data' do
        result = service.get_current_weather(address)

        expect(result).to include(:daily_forecast)
        expect(result[:daily_forecast]).to be_an(Array)
        expect(result[:daily_forecast]).not_to be_empty

        forecast_day = result[:daily_forecast].first
        expect(forecast_day).to include(:date, :high, :low, :description)
      end
    end

    context 'when address is invalid' do
      let(:invalid_address) { 'InvalidLocationThatDoesNotExist123456' }

      it 'returns an error message', :vcr do
        result = service.get_current_weather(invalid_address)

        expect(result).to be_a(Hash)
        expect(result).to include(:error)
        expect(result[:error]).to be_present
      end
    end

    context 'caching behavior' do
      it 'caches weather data for subsequent requests' do
        # Clear any existing cache
        Rails.cache.clear

        # Mock the geocoding and weather API responses to avoid real HTTP calls
        coordinates = { lat: 49.2827, lon: -123.1207, location_name: 'Vancouver, BC' }
        weather_data = {
          'current' => {
            'temperature_2m' => 75.0,
            'apparent_temperature' => 76.0,
            'relative_humidity_2m' => 60.0,
            'weather_code' => 0,
            'wind_speed_10m' => 5.0
          },
          'daily' => {
            'time' => ['2025-08-01', '2025-08-02'],
            'temperature_2m_max' => [80.0, 82.0],
            'temperature_2m_min' => [65.0, 67.0],
            'weather_code' => [0, 1]
          }
        }

        allow(NominatimGeocodingService).to receive(:geocode).with(address).and_return(coordinates)
        allow(service).to receive(:fetch_weather_data).and_return(weather_data)

        # First request should fetch fresh data
        first_result = service.get_current_weather(address)
        expect(first_result[:from_cache]).to be false

        # Second request should use cached data
        second_result = service.get_current_weather(address)
        expect(second_result[:from_cache]).to be true
        expect(second_result[:cached_at]).to eq(first_result[:cached_at])
      end
    end
  end

  describe 'private methods' do
    describe '#normalize_address_for_cache' do
      it 'normalizes addresses for consistent cache keys' do
        normalized = service.send(:normalize_address_for_cache, 'Vancouver, BC')
        expect(normalized).to eq('vancouver_bc')

        normalized = service.send(:normalize_address_for_cache, '  San Francisco,  CA  ')
        expect(normalized).to eq('san_francisco_ca')

        normalized = service.send(:normalize_address_for_cache, 'Los Angeles - CA')
        expect(normalized).to eq('los_angeles__ca')
      end
    end
  end
end
