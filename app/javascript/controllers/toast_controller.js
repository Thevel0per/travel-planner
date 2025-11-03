import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toast"
// Provides auto-dismiss functionality for toast notifications
export default class extends Controller {
  static values = { 
    timeout: { type: Number, default: 5000 },
    type: { type: String, default: 'notice' }
  }

  connect() {
    // Start auto-dismiss timer when toast is connected to DOM
    this.startTimer()
  }

  disconnect() {
    // Clear timer when component is removed from DOM
    this.clearTimer()
  }

  dismiss() {
    // Remove toast from DOM
    // The controller element itself is the toast
    this.element.classList.add('hidden')
    // Remove from DOM after animation completes
    setTimeout(() => {
      if (this.element && this.element.parentNode) {
        this.element.parentNode.removeChild(this.element)
      }
    }, 300) // Match CSS transition duration
  }

  startTimer() {
    // Use different timeout based on toast type
    // Error toasts (alert) get longer timeout (7 seconds)
    // Success toasts (notice) get shorter timeout (5 seconds)
    const timeoutDuration = this.typeValue === 'alert' ? 7000 : this.timeoutValue
    
    this.timeoutId = setTimeout(() => {
      this.dismiss()
    }, timeoutDuration)
  }

  clearTimer() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }
  }
}

