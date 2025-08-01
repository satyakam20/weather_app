require 'rails_helper'

RSpec.describe WeatherController, type: :controller do
  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns instance variables' do
      session[:weather_data] = { 'location' => 'Test Location' }
      session[:last_address] = 'Test Address'

      get :index

      expect(assigns(:weather_data)).to eq({ 'location' => 'Test Location' })
      expect(assigns(:address)).to eq('Test Address')
    end

    it 'clears session data after displaying' do
      session[:weather_data] = { 'location' => 'Test Location' }
      session[:last_address] = 'Test Address'

      get :index

      expect(session[:weather_data]).to be_nil
      expect(session[:last_address]).to be_nil
    end
  end

  describe 'GET #autocomplete' do
    let(:mock_suggestions) do
      [
        { display_name: 'Vancouver, BC', full_address: 'Vancouver, British Columbia, Canada' },
        { display_name: 'Vancouver, WA', full_address: 'Vancouver, Washington, United States' }
      ]
    end

    before do
      allow(NominatimGeocodingService).to receive(:search_suggestions).and_return(mock_suggestions)
    end

    it 'returns JSON suggestions for valid query' do
      get :autocomplete, params: { q: 'Vancouver' }, format: :json

      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
      
      json_response = JSON.parse(response.body)
      expect(json_response).to eq(mock_suggestions.map(&:stringify_keys))
    end

    it 'returns empty array for short query' do
      get :autocomplete, params: { q: 'N' }, format: :json

      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response).to eq([])
    end

    it 'returns empty array for missing query' do
      get :autocomplete, format: :json

      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response).to eq([])
    end
  end

  describe 'POST #forecast' do
    let(:mock_weather_data) do
      {
        location: 'Vancouver, BC',
        current_temp: 75,
        description: 'Sunny',
        from_cache: false,
        cached_at: Time.current.iso8601
      }
    end

    let(:mock_weather_service) { instance_double(WeatherService) }

    before do
      allow(WeatherService).to receive(:new).and_return(mock_weather_service)
    end

    context 'with valid address' do
      it 'fetches weather data and redirects with success message' do
        allow(mock_weather_service).to receive(:get_current_weather)
          .with('Vancouver, BC')
          .and_return(mock_weather_data)

        post :forecast, params: { address: 'Vancouver, BC' }

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Weather forecast retrieved successfully!')
        expect(session[:weather_data]).to eq(mock_weather_data)
        expect(session[:last_address]).to eq('Vancouver, BC')
      end

      it 'shows cache message for cached data' do
        cached_data = mock_weather_data.merge(from_cache: true)
        allow(mock_weather_service).to receive(:get_current_weather)
          .with('Vancouver, BC')
          .and_return(cached_data)

        post :forecast, params: { address: 'Vancouver, BC' }

        expect(flash[:notice]).to eq('Weather forecast retrieved from cache!')
      end
    end

    context 'with invalid address' do
      it 'shows error message when weather service returns error' do
        allow(mock_weather_service).to receive(:get_current_weather)
          .with('InvalidLocation')
          .and_return({ error: 'Location not found' })

        post :forecast, params: { address: 'InvalidLocation' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Location not found')
      end
    end

    context 'with empty address' do
      it 'shows validation error message' do
        post :forecast, params: { address: '' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Please enter a valid address')
      end
    end
  end

  describe 'DELETE #clear_cache' do
    it 'clears cache for specific address' do
      expect(Rails.cache).to receive(:delete).with('weather_forecast:vancouver_bc')

      delete :clear_cache, params: { address: 'Vancouver, BC' }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq('Cache cleared for Vancouver, BC')
    end

    it 'clears all cache when no address provided' do
      expect(Rails.cache).to receive(:clear)

      delete :clear_cache

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq('All weather cache cleared')
    end
  end
end
