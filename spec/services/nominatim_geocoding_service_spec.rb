require 'rails_helper'

RSpec.describe NominatimGeocodingService, type: :service do
  describe '.geocode' do
    context 'when location is found', :vcr do
      it 'returns coordinates and location name for valid address' do
        result = NominatimGeocodingService.geocode('Vancouver, BC')

        expect(result).to be_a(Hash)
        expect(result).to include(:lat, :lon, :location_name)
        expect(result[:lat]).to be_a(Float)
        expect(result[:lon]).to be_a(Float)
        expect(result[:location_name]).to be_present
        expect(result[:location_name]).to include('Vancouver')
      end
    end

    context 'when location is not found', :vcr do
      it 'returns nil for invalid address' do
        result = NominatimGeocodingService.geocode('InvalidLocationThatDoesNotExist123456')

        expect(result).to be_nil
      end
    end

    context 'when API is unavailable' do
      it 'handles network errors gracefully' do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new('Network error'))

        result = NominatimGeocodingService.geocode('Vancouver, BC')

        expect(result).to be_nil
      end
    end
  end

  describe '.search_suggestions' do
    context 'when query returns results', :vcr do
      it 'returns array of suggestions' do
        results = NominatimGeocodingService.search_suggestions('Vancouver')

        expect(results).to be_an(Array)
        expect(results).not_to be_empty
        expect(results.size).to be <= 5

        first_result = results.first
        expect(first_result).to include(:display_name, :full_address)
        expect(first_result[:display_name]).to be_present
        expect(first_result[:full_address]).to be_present
      end
    end

    context 'when query returns no results', :vcr do
      it 'returns empty array for invalid query' do
        results = NominatimGeocodingService.search_suggestions('InvalidLocationThatDoesNotExist123456')

        expect(results).to eq([])
      end
    end

    context 'when API is unavailable' do
      it 'handles network errors gracefully' do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new('Network error'))

        results = NominatimGeocodingService.search_suggestions('Vancouver')

        expect(results).to eq([])
      end
    end
  end

  describe '.format_location_name' do
    it 'formats location with city, state, and country' do
      location_data = {
        'address' => {
          'city' => 'Vancouver',
          'state' => 'British Columbia',
          'country' => 'Canada'
        }
      }

      result = NominatimGeocodingService.send(:format_location_name, location_data)

      expect(result).to eq('Vancouver, British Columbia, Canada')
    end

    it 'handles missing address components' do
      location_data = {
        'address' => {
          'town' => 'Springfield',
          'country' => 'United States'
        }
      }

      result = NominatimGeocodingService.send(:format_location_name, location_data)

      expect(result).to eq('Springfield, United States')
    end

    it 'falls back to display_name when no address components' do
      location_data = {
        'display_name' => 'Some Location, Somewhere',
        'address' => {}
      }

      result = NominatimGeocodingService.send(:format_location_name, location_data)

      expect(result).to eq('Some Location, Somewhere')
    end
  end
end
