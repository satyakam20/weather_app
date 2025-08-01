class WeatherController < ApplicationController
  def index
    @address = session[:last_address]
    @weather_data = session[:weather_data]
    @message = flash[:notice]
    @error = flash[:alert]
    
    session[:weather_data] = nil
    session[:last_address] = nil
  end

  def autocomplete
    query = params[:q]
    if query.present? && query.length >= 2
      suggestions = NominatimGeocodingService.search_suggestions(query)
      render json: suggestions
    else
      render json: []
    end
  end

  def forecast
    address = params[:address]
    
    if params[:user_timezone].present?
      session[:user_timezone] = params[:user_timezone]
    end
    
    if address.present?
      weather_service = ::WeatherService.new
      weather_data = weather_service.get_current_weather(address)
      
      if weather_data[:error]
        flash[:alert] = weather_data[:error]
      else
        session[:weather_data] = weather_data
        session[:last_address] = address
        if weather_data[:from_cache]
          flash[:notice] = "Weather forecast retrieved from cache!"
        else
          flash[:notice] = "Weather forecast retrieved successfully!"
        end
      end
    else
      flash[:alert] = "Please enter a valid address"
    end
    
    redirect_to root_path
  end

  def clear_cache
    if params[:address].present?
      cache_key = "weather_forecast:#{normalize_address_for_cache(params[:address])}"
      Rails.cache.delete(cache_key)
      flash[:notice] = "Cache cleared for #{params[:address]}"
    else
      Rails.cache.clear
      flash[:notice] = "All weather cache cleared"
    end
    redirect_to root_path
  end

  def set_timezone
    if params[:timezone].present?
      session[:user_timezone] = params[:timezone]
      render json: { status: 'success' }
    else
      render json: { status: 'error' }, status: 400
    end
  end

  private

  def normalize_address_for_cache(address)
    address.to_s.strip.downcase.gsub(/\s+/, '_').gsub(/[^a-z0-9_]/, '')
  end

  def weather_params
    params.permit(:address)
  end
end
