import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="material-tailwind"
export default class extends Controller {
  connect() {
    // Initialize Material Tailwind ripple effects
    this.initializeRipple()
  }

  disconnect() {
    // Cleanup if needed
  }

  initializeRipple() {
    // Material Tailwind's ripple script will automatically handle
    // elements with data-ripple attribute when they're clicked
    // This controller ensures the initialization happens after Turbo navigation
    
    const rippleElements = this.element.querySelectorAll('[data-ripple]')
    
    rippleElements.forEach(element => {
      // Ensure ripple is properly initialized
      if (window.ripple && typeof window.ripple === 'function') {
        window.ripple(element)
      }
    })
  }

  // Re-initialize on Turbo navigation
  turboLoad() {
    this.initializeRipple()
  }
}

