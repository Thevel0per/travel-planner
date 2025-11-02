import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="accordion"
// Provides expand/collapse functionality for accordion items
export default class extends Controller {
  static targets = ["content", "button", "icon"]

  connect() {
    // Initialize: content should be hidden by default unless data-expanded="true"
    const expanded = this.element.dataset.expanded === "true"
    this.toggleContent(expanded)
  }

  toggle(event) {
    event.preventDefault()
    const isExpanded = !this.contentTarget.classList.contains('hidden')
    this.toggleContent(!isExpanded)
  }

  toggleContent(expanded) {
    // Toggle content visibility
    if (this.hasContentTarget) {
      if (expanded) {
        this.contentTarget.classList.remove('hidden')
        this.contentTarget.setAttribute('aria-hidden', 'false')
      } else {
        this.contentTarget.classList.add('hidden')
        this.contentTarget.setAttribute('aria-hidden', 'true')
      }
    }

    // Update button aria-expanded attribute
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('aria-expanded', expanded.toString())
    }

    // Rotate chevron icon
    if (this.hasIconTarget) {
      if (expanded) {
        this.iconTarget.classList.remove('rotate-0')
        this.iconTarget.classList.add('rotate-180')
      } else {
        this.iconTarget.classList.remove('rotate-180')
        this.iconTarget.classList.add('rotate-0')
      }
    }
  }
}

