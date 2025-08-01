// Unit conversion functionality
function initializeUnitToggle() {
  const unitToggle = document.getElementById('unitToggle');
  const weatherApp = document.querySelector('.weather-app');
  
  if (!unitToggle || !weatherApp) return;
  
  const savedUnit = localStorage.getItem('weatherUnit');
  if (savedUnit === 'metric') {
    unitToggle.checked = true;
    convertToMetric();
  }
  
  unitToggle.removeEventListener('change', handleToggleChange);
  unitToggle.addEventListener('change', handleToggleChange);
  
  function handleToggleChange() {
    if (unitToggle.checked) {
      convertToMetric();
      localStorage.setItem('weatherUnit', 'metric');
    } else {
      convertToImperial();
      localStorage.setItem('weatherUnit', 'imperial');
    }
  }
  
  function convertToMetric() {
    weatherApp.classList.add('metric-mode');
    
    // converf temperatures (F to C)
    const tempElements = document.querySelectorAll('[data-temp-f]');
    tempElements.forEach(element => {
      const fahrenheit = parseFloat(element.getAttribute('data-temp-f'));
      const celsius = Math.round((fahrenheit - 32) * 5/9);
      
      if (element.classList.contains('temp-current')) {
        element.textContent = `${celsius}°C`;
      } else if (element.classList.contains('temp-feels-like')) {
        element.textContent = `${celsius}°C`;
      } else if (element.classList.contains('temp-high')) {
        element.textContent = `High: ${celsius}°`;
      } else if (element.classList.contains('temp-low')) {
        element.textContent = `Low: ${celsius}°`;
      } else if (element.classList.contains('forecast-temp')) {
        element.textContent = `${celsius}°`;
      }
    });
    
    // convert wind (mph to km/h)
    const windElements = document.querySelectorAll('[data-speed-mph]');
    windElements.forEach(element => {
      const mph = parseFloat(element.getAttribute('data-speed-mph'));
      const kmh = Math.round(mph * 1.60934 * 10) / 10; // Round to 1 decimal
      element.textContent = `${kmh} km/h`;
    });
  }
  
  function convertToImperial() {
    weatherApp.classList.remove('metric-mode');
    
    const tempElements = document.querySelectorAll('[data-temp-f]');
    tempElements.forEach(element => {
      const fahrenheit = parseFloat(element.getAttribute('data-temp-f'));
      
      if (element.classList.contains('temp-current')) {
        element.textContent = `${fahrenheit}°F`;
      } else if (element.classList.contains('temp-feels-like')) {
        element.textContent = `${fahrenheit}°F`;
      } else if (element.classList.contains('temp-high')) {
        element.textContent = `High: ${fahrenheit}°`;
      } else if (element.classList.contains('temp-low')) {
        element.textContent = `Low: ${fahrenheit}°`;
      } else if (element.classList.contains('forecast-temp')) {
        element.textContent = `${fahrenheit}°`;
      }
    });
    
    const windElements = document.querySelectorAll('[data-speed-mph]');
    windElements.forEach(element => {
      const mph = parseFloat(element.getAttribute('data-speed-mph'));
      element.textContent = `${mph} mph`;
    });
  }
}

document.addEventListener('DOMContentLoaded', initializeUnitToggle);
document.addEventListener('turbo:load', initializeUnitToggle);
document.addEventListener('turbo:render', initializeUnitToggle);
