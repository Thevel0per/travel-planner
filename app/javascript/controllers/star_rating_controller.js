import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="star-rating"
// Handles clickable star rating (1-10 scale) with auto-submit
export default class extends Controller {
  static targets = ["star", "ratingDisplay"]

  connect() {
    // Initialize stars based on current rating value
    const currentRating = this.getCurrentRating()
    this.updateStarsDisplay(currentRating)
    this.updateRatingDisplay(currentRating)
    
    // Debug logging (can be removed later)
    console.log('Star rating controller connected', {
      currentRating,
      starTargets: this.hasStarTargets ? this.starTargets.length : 0,
      formFound: !!this.element.querySelector('form')
    })
  }

  selectRating(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const rating = parseInt(event.currentTarget.dataset.starValue)
    
    console.log('Star clicked, rating:', rating)
    
    if (isNaN(rating) || rating < 1 || rating > 10) {
      console.error('Invalid rating value:', rating)
      return
    }
    
    // Update hidden input field
    const ratingInput = this.element.querySelector('#generated_plan_rating')
    if (ratingInput) {
      ratingInput.value = rating
      console.log('Updated rating input to:', rating)
    } else {
      console.error('Rating input field not found')
      return
    }
    
    // Update star display immediately for visual feedback
    this.updateStarsDisplay(rating)
    this.updateRatingDisplay(rating)
    console.log('Updated star display')
    
    // Auto-submit the form using Turbo
    const form = this.element.querySelector('form')
    if (form) {
      console.log('Submitting form...')
      // Use Turbo's submit method (requestSubmit triggers Turbo)
      form.requestSubmit()
    } else {
      console.error('Form not found in element:', this.element)
    }
  }

  getCurrentRating() {
    const ratingInput = this.element.querySelector('#generated_plan_rating')
    if (!ratingInput) return 0
    
    const value = parseInt(ratingInput.value)
    return isNaN(value) ? 0 : value
  }

  updateStarsDisplay(rating) {
    if (!this.hasStarTargets) return
    
    this.starTargets.forEach((starButton) => {
      const starValue = parseInt(starButton.dataset.starValue)
      const starSvg = starButton.querySelector('svg')
      
      if (starSvg) {
        if (starValue <= rating) {
          starSvg.classList.remove('text-gray-300')
          starSvg.classList.add('text-yellow-400')
        } else {
          starSvg.classList.remove('text-yellow-400')
          starSvg.classList.add('text-gray-300')
        }
      }
    })
  }

  updateRatingDisplay(rating) {
    if (this.hasRatingDisplayTarget) {
      this.ratingDisplayTarget.textContent = rating
    }
  }
}

