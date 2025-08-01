// Address autocomplete functionality
function initializeAddressAutocomplete() {
  const addressInput = document.getElementById('address');
  const autocompleteContainer = document.createElement('div');
  autocompleteContainer.className = 'autocomplete-suggestions';
  
  if (!addressInput) return;
  
  addressInput.parentNode.insertBefore(autocompleteContainer, addressInput.nextSibling);
  
  let debounceTimer;
  let currentSuggestions = [];
  let selectedIndex = -1;
  
  // for input changes
  addressInput.addEventListener('input', function() {
    const query = this.value.trim();
    
    clearTimeout(debounceTimer);
    
    if (query.length < 2) {
      hideSuggestions();
      return;
    }
    
    debounceTimer = setTimeout(() => {
      fetchSuggestions(query);
    }, 300);
  });
  
  // Handle keyboard navigation
  addressInput.addEventListener('keydown', function(e) {
    const suggestions = autocompleteContainer.querySelectorAll('.suggestion-item');
    
    switch(e.key) {
      case 'ArrowDown':
        e.preventDefault();
        selectedIndex = Math.min(selectedIndex + 1, suggestions.length - 1);
        updateSelection(suggestions);
        break;
      case 'ArrowUp':
        e.preventDefault();
        selectedIndex = Math.max(selectedIndex - 1, -1);
        updateSelection(suggestions);
        break;
      case 'Enter':
        if (selectedIndex >= 0 && suggestions[selectedIndex]) {
          e.preventDefault();
          selectSuggestion(currentSuggestions[selectedIndex]);
        }
        break;
      case 'Escape':
        hideSuggestions();
        break;
    }
  });
  
  // Hide suggestions when clicking outside
  document.addEventListener('click', function(e) {
    if (!addressInput.contains(e.target) && !autocompleteContainer.contains(e.target)) {
      hideSuggestions();
    }
  });
  
  function fetchSuggestions(query) {
    fetch(`/weather/autocomplete?q=${encodeURIComponent(query)}`, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(suggestions => {
      currentSuggestions = suggestions;
      displaySuggestions(suggestions);
    })
    .catch(error => {
      console.error('Autocomplete error:', error);
      hideSuggestions();
    });
  }
  
  function displaySuggestions(suggestions) {
    autocompleteContainer.innerHTML = '';
    selectedIndex = -1;
    
    if (suggestions.length === 0) {
      hideSuggestions();
      return;
    }
    
    suggestions.forEach((suggestion, index) => {
      const item = document.createElement('div');
      item.className = 'suggestion-item';
      item.innerHTML = `
        <div class="suggestion-main">${suggestion.display_name}</div>
        <div class="suggestion-full">${suggestion.full_address}</div>
      `;
      
      item.addEventListener('click', () => {
        selectSuggestion(suggestion);
      });
      
      autocompleteContainer.appendChild(item);
    });
    
    autocompleteContainer.style.display = 'block';
  }
  
  function updateSelection(suggestions) {
    suggestions.forEach((item, index) => {
      if (index === selectedIndex) {
        item.classList.add('selected');
      } else {
        item.classList.remove('selected');
      }
    });
  }
  
  function selectSuggestion(suggestion) {
    addressInput.value = suggestion.display_name;
    hideSuggestions();
    addressInput.focus();
  }
  
  function hideSuggestions() {
    autocompleteContainer.style.display = 'none';
    selectedIndex = -1;
  }
}

// Initialize on page load and after Turbo navigation
document.addEventListener('DOMContentLoaded', initializeAddressAutocomplete);
document.addEventListener('turbo:load', initializeAddressAutocomplete);
document.addEventListener('turbo:render', initializeAddressAutocomplete);
