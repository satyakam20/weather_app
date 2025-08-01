# Weather App

A modern Rails weather application that provides current weather conditions and 5-day forecasts for any location worldwide. Built with Rails 8, featuring real-time address autocomplete, intelligent caching, and unit conversion capabilities.

![Rails](https://img.shields.io/badge/Rails-8.0.2-red.svg)
![Ruby](https://img.shields.io/badge/Ruby-3.3+-red.svg)
![SQLite](https://img.shields.io/badge/Database-SQLite3-blue.svg)
![Tests](https://img.shields.io/badge/Tests-RSpec-green.svg)


### Quick Start

#### Prerequisites
- Ruby 3.3+ 
- Rails 8.0.2
- SQLite3
- Node.js (for asset compilation)

#### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd weather_app
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

4. **Start the server**
   ```bash
   bin/rails server
   ```

5. **Visit the application**
   ```
   http://localhost:3000
   ```

### Demo

![Weather App Demo](weather-app-demo.gif)

**Live Demo Features Showcase:**

- **Autocomplete:** Real-time address suggestions as you type with debounced search
- **Weather Display:** Current conditions with temperature, humidity, wind speed, and weather description
- **5-Day Forecast:** Daily weather predictions with high/low temperatures and conditions
- **Unit Conversion:** Seamless toggle between Fahrenheit/Celsius and mph/km/h with instant updates
- **Caching:** 30-minute cache system with visual indicators for faster repeat searches


*The demo demonstrates user journey from address input through weather data display, highlighting all interactive features and smooth user experience.*

### Architecture

#### Tech Stack
- **Backend**: Ruby on Rails 8.0.2
- **Database**: SQLite3 (development, test, production)
- **Frontend**: Rails front end
- **APIs**: Open-Meteo (weather), Nominatim (geocoding)
- **Caching**: Solid Cache
- **Testing**: RSpec, Capybara, VCR, WebMock

#### Key Components

##### Services
- **`WeatherService`**: Handles weather data fetching and caching
- **`NominatimGeocodingService`**: Manages address geocoding and autocomplete

##### Controllers
- **`WeatherController`**: Main application controller with weather, autocomplete, and cache management

##### JavaScript Modules
- **`unit_converter.js`**: Temperature and wind speed unit conversion
- **`address_autocomplete.js`**: Real-time address suggestions

### API Integration

#### Weather Data - Open-Meteo
- **Endpoint**: `https://api.open-meteo.com/v1/forecast`
- **Features**: Current conditions, daily forecasts, no API key required
- **Data**: Temperature, humidity, wind, weather codes

#### Geocoding - Nominatim (OpenStreetMap)
- **Endpoint**: `https://nominatim.openstreetmap.org`
- **Features**: Address search, autocomplete suggestions
- **Coverage**: Worldwide location data

### Testing

The application includes comprehensive test coverage using RSpec:

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/services/weather_service_spec.rb
```

### Configuration

#### Environment Variables
No API keys required! Both Open-Meteo and Nominatim are free services.

#### Cache Configuration
```ruby
# config/environments/development.rb
config.cache_store = :solid_cache_store

# config/environments/production.rb  
config.cache_store = :solid_cache_store

# config/environments/test.rb
config.cache_store = :memory_store
```

### Deployment

#### Production Setup
1. **Environment Configuration**
   ```bash
   RAILS_ENV=production bundle exec rails assets:precompile
   RAILS_ENV=production bundle exec rails db:migrate
   ```

2. **Database**
   - SQLite3 configured for all environments
   - Automatic schema management via Rails migrations

3. **Assets**
   - Propshaft asset pipeline
   - Importmap for JavaScript modules
   - No Node.js build process required in production
