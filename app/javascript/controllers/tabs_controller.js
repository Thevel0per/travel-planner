import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    // Read tab from URL query parameter or hash
    const urlParams = new URLSearchParams(window.location.search)
    const tabFromUrl = urlParams.get('tab')
    const tabFromHash = window.location.hash.replace('#', '')
    const initialTabId = tabFromUrl || tabFromHash
    
    if (initialTabId) {
      // Set active tab from URL
      this.updateActiveTab(initialTabId)
    } else {
      // Fallback: Set initial active tab based on visible panel
    const activePanel = this.panelTargets.find(panel => !panel.classList.contains('hidden'))
    if (activePanel) {
      const activeTabId = activePanel.dataset.panelId
      this.updateActiveTab(activeTabId)
      }
    }
    
    // Attach keyboard navigation listeners
    this.element.addEventListener('keydown', this.handleKeyboardNavigation.bind(this))
  }

  disconnect() {
    // Remove keyboard navigation listeners
    this.element.removeEventListener('keydown', this.handleKeyboardNavigation.bind(this))
  }

  switchTab(event) {
    event.preventDefault()
    const tabId = event.currentTarget.dataset.tabId
    this.updateActiveTab(tabId)
    
    // Update URL query parameter for persistence across page refreshes
    if (window.history && window.history.pushState) {
      const url = new URL(window.location)
      url.searchParams.set('tab', tabId)
      // Remove hash if present
      url.hash = ''
      window.history.pushState(null, '', url)
    }
  }

  handleKeyboardNavigation(event) {
    const tabs = this.tabTargets
    const currentIndex = tabs.findIndex(tab => tab.getAttribute('aria-selected') === 'true')
    
    let newIndex = currentIndex
    
    switch(event.key) {
      case 'ArrowLeft':
        event.preventDefault()
        newIndex = currentIndex > 0 ? currentIndex - 1 : tabs.length - 1
        break
      case 'ArrowRight':
        event.preventDefault()
        newIndex = currentIndex < tabs.length - 1 ? currentIndex + 1 : 0
        break
      case 'Home':
        event.preventDefault()
        newIndex = 0
        break
      case 'End':
        event.preventDefault()
        newIndex = tabs.length - 1
        break
      default:
        return // Ignore other keys
    }
    
    tabs[newIndex].focus()
    tabs[newIndex].click()
  }

  updateActiveTab(tabId) {
    // Update all tabs
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tabId === tabId
      tab.setAttribute('aria-selected', isActive ? 'true' : 'false')
      
      // Update styling classes
      if (isActive) {
        tab.classList.remove('text-gray-500', 'hover:text-gray-700', 'hover:border-b-2', 'hover:border-gray-300')
        tab.classList.add('text-blue-600', 'border-b-2', 'border-blue-600')
      } else {
        tab.classList.remove('text-blue-600', 'border-b-2', 'border-blue-600')
        tab.classList.add('text-gray-500', 'hover:text-gray-700', 'hover:border-b-2', 'hover:border-gray-300')
      }
    })
    
    // Update all panels
    this.panelTargets.forEach(panel => {
      const isActive = panel.dataset.panelId === tabId
      if (isActive) {
        panel.classList.remove('hidden')
      } else {
        panel.classList.add('hidden')
      }
    })
  }
}

