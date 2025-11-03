import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
// Provides mobile sidebar toggle functionality with keyboard support
export default class extends Controller {
  static targets = ["sidebar", "overlay", "toggleButton"]

  connect() {
    // Check if we're on desktop (lg breakpoint = 1024px)
    this.isDesktop = window.matchMedia('(min-width: 1024px)').matches
    
    // Initialize sidebar state: closed by default on mobile, always open on desktop
    this.isOpen = this.isDesktop
    
    // Ensure initial state is correct
    this.updateVisibility()
    
    // Listen for screen size changes
    this.mediaQuery = window.matchMedia('(min-width: 1024px)')
    this.mediaQueryHandler = (e) => {
      this.isDesktop = e.matches
      if (this.isDesktop) {
        // On desktop, sidebar is always visible
        this.isOpen = true
      } else {
        // On mobile, sidebar should be closed
        this.isOpen = false
      }
      this.updateVisibility()
    }
    this.mediaQuery.addEventListener('change', this.mediaQueryHandler)
    
    // Attach keyboard event listener for Escape key
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.boundHandleEscape)
    
    // Close sidebar on Turbo navigation (when user navigates to a new page)
    this.boundHandleTurboNavigation = this.handleTurboNavigation.bind(this)
    document.addEventListener('turbo:before-visit', this.boundHandleTurboNavigation)
  }

  disconnect() {
    // Clean up event listeners
    if (this.mediaQuery && this.mediaQueryHandler) {
      this.mediaQuery.removeEventListener('change', this.mediaQueryHandler)
    }
    document.removeEventListener('keydown', this.boundHandleEscape)
    document.removeEventListener('turbo:before-visit', this.boundHandleTurboNavigation)
  }

  toggle() {
    // Only allow toggle on mobile (desktop sidebar is always visible)
    if (!this.isDesktop) {
      if (this.isOpen) {
        this.close()
      } else {
        this.open()
      }
    }
  }

  open() {
    this.isOpen = true
    this.updateVisibility()
  }

  close() {
    this.isOpen = false
    this.updateVisibility()
  }

  handleEscape(event) {
    if (event.key === 'Escape' && this.isOpen) {
      this.close()
      // Return focus to toggle button for accessibility
      if (this.hasToggleButtonTarget) {
        this.toggleButtonTarget.focus()
      }
    }
  }

  handleTurboNavigation() {
    // Auto-close sidebar when navigating to a new page
    if (this.isOpen) {
      this.close()
    }
  }

  updateVisibility() {
    if (this.hasSidebarTarget) {
      if (this.isDesktop) {
        // On desktop, sidebar is always visible (handled by CSS lg:translate-x-0)
        this.sidebarTarget.setAttribute('aria-hidden', 'false')
      } else {
        // On mobile, manage visibility via transform classes
        if (this.isOpen) {
          this.sidebarTarget.classList.remove('-translate-x-full')
          this.sidebarTarget.classList.add('translate-x-0')
          this.sidebarTarget.setAttribute('aria-hidden', 'false')
        } else {
          this.sidebarTarget.classList.remove('translate-x-0')
          this.sidebarTarget.classList.add('-translate-x-full')
          this.sidebarTarget.setAttribute('aria-hidden', 'true')
        }
      }
    }

    if (this.hasOverlayTarget) {
      // Overlay only shows on mobile when sidebar is open
      if (!this.isDesktop && this.isOpen) {
        this.overlayTarget.classList.remove('hidden')
        this.overlayTarget.setAttribute('aria-hidden', 'false')
      } else {
        this.overlayTarget.classList.add('hidden')
        this.overlayTarget.setAttribute('aria-hidden', 'true')
      }
    }

    // Update toggle button aria-expanded
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.setAttribute('aria-expanded', this.isOpen.toString())
    }
  }
}

