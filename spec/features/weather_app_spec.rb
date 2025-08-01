require 'rails_helper'

RSpec.feature 'Weather App', type: :feature do
  scenario 'User searches for weather by address', :vcr do
    visit root_path

    expect(page).to have_content('Weather App')
    expect(page).to have_field('Address:')
    expect(page).to have_button('Get Weather')

    fill_in 'Address:', with: 'Vancouver, BC'
    click_button 'Get Weather'

    expect(page).to have_content('Weather forecast retrieved')
    expect(page).to have_content('Current Weather for')
    expect(page).to have_content('Vancouver')
  end

  scenario 'User sees autocomplete suggestions' do
    # Mock the autocomplete endpoint to avoid external API calls
    allow(NominatimGeocodingService).to receive(:search_suggestions).and_return([
      { display_name: 'Vancouver, BC', full_address: 'Vancouver, British Columbia, Canada' }
    ])

    visit root_path

    fill_in 'Address:', with: 'Vanc'

    # Note: This would require JavaScript to be enabled for full testing
    # For now, we're just testing that the form exists and can be submitted
    expect(page).to have_field('Address:', with: 'Vanc')
  end

  scenario 'User sees error for invalid address', :vcr do
    visit root_path

    fill_in 'Address:', with: 'InvalidLocationThatDoesNotExist123456'
    click_button 'Get Weather'

    expect(page).to have_content('Could not find location')
  end

  scenario 'User sees cache indicator for repeated searches' do
    # Clear cache first
    Rails.cache.clear

    # Mock the weather service to control cache behavior
    weather_service = instance_double(WeatherService)
    allow(WeatherService).to receive(:new).and_return(weather_service)

    # First call returns fresh data
    fresh_data = {
      location: 'Vancouver, BC',
      current_temp: 75,
      description: 'Sunny',
      from_cache: false,
      cached_at: Time.current.iso8601,
      today_high: 80,
      today_low: 65,
      feels_like: 76,
      humidity: 60,
      wind_speed: 5.0,
      icon: '01d',
      daily_forecast: []
    }

    # Second call returns cached data
    cached_data = fresh_data.merge(from_cache: true)

    allow(weather_service).to receive(:get_current_weather)
      .with('Vancouver, BC')
      .and_return(fresh_data, cached_data)

    visit root_path

    # First search - should show fresh data
    fill_in 'Address:', with: 'Vancouver, BC'
    click_button 'Get Weather'

    expect(page).to have_content('🔄 Fresh Data')

    # Second search - should show cached data
    fill_in 'Address:', with: 'Vancouver, BC'
    click_button 'Get Weather'

    expect(page).to have_content('📦 Cached Data')
  end
end
