import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="note-edit"
// Handles inline editing and deletion of notes
export default class extends Controller {
  static targets = [
    "displayMode",
    "editMode",
    "textarea",
    "form",
    "saveButton",
    "cancelButton",
    "editButton",
    "deleteButton"
  ]

  static values = {
    originalContent: String
  }

  connect() {
    // Initialize state: start in display mode
    this.isEditing = false
    this.isSubmitting = false
    this.originalContent = ""
    
    // Ensure display mode is visible and edit mode is hidden
    this.showDisplayMode()
    this.hideEditMode()
  }

  // Enter edit mode
  edit(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.isEditing || this.isSubmitting) return
    
    // Get current content from display mode
    // The content is in a div with formatted text, we need to extract the plain text
    let currentContent = ""
    if (this.hasDisplayModeTarget) {
      const contentContainer = this.displayModeTarget.querySelector('.mb-3, p, div')
      if (contentContainer) {
        // Get all text nodes, preserving line breaks
        currentContent = this.extractTextContent(contentContainer)
      }
    }
    
    // Store original content
    this.originalContent = currentContent.trim()
    
    // Set textarea value to current content
    if (this.hasTextareaTarget) {
      this.textareaTarget.value = this.originalContent
    }
    
    // Switch to edit mode
    this.isEditing = true
    this.hideDisplayMode()
    this.showEditMode()
    
    // Focus textarea after a brief delay to ensure it's visible
    if (this.hasTextareaTarget) {
      setTimeout(() => {
        this.textareaTarget.focus()
        // Move cursor to end
        const length = this.textareaTarget.value.length
        this.textareaTarget.setSelectionRange(length, length)
      }, 50)
    }
  }

  // Extract text content from an element, preserving line breaks
  extractTextContent(element) {
    let text = ""
    const walker = document.createTreeWalker(
      element,
      NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT,
      null,
      false
    )
    
    let node
    while (node = walker.nextNode()) {
      if (node.nodeType === Node.TEXT_NODE) {
        text += node.textContent
      } else if (node.nodeName === 'BR' || node.nodeName === 'P' || node.nodeName === 'DIV') {
        // Add line break for block elements
        if (text && !text.endsWith('\n')) {
          text += '\n'
        }
      }
    }
    
    return text.trim()
  }

  // Cancel edit mode and restore original content
  cancel(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (!this.isEditing || this.isSubmitting) return
    
    // Restore original content
    if (this.hasTextareaTarget) {
      this.textareaTarget.value = this.originalContent
    }
    
    // Clear any validation errors
    this.clearErrors()
    
    // Switch back to display mode
    this.isEditing = false
    this.hideEditMode()
    this.showDisplayMode()
  }

  // Handle form submission
  handleSubmit(event) {
    // Prevent double submission
    if (this.isSubmitting) {
      event.preventDefault()
      return
    }
    
    // Client-side validation
    if (this.hasTextareaTarget) {
      const content = this.textareaTarget.value.trim()
      
      if (!content) {
        event.preventDefault()
        this.showError("Content can't be blank")
        return
      }
      
      if (content.length > 10000) {
        event.preventDefault()
        this.showError("Content is too long (maximum is 10000 characters)")
        return
      }
    }
    
    // Set submitting state
    this.isSubmitting = true
    this.disableFormButtons()
    
    // Let Turbo handle the submission
    // The form will submit normally, and we'll handle the response via Turbo events
  }

  // Handle Turbo form submission end event
  handleFormSubmit(event) {
    // Check if this event is for our edit form
    const form = event.target.closest('form')
    const isOurForm = form && this.hasFormTarget && form === this.formTarget
    
    // Also check if the event originated from within our controller element
    const isFromOurController = event.target.closest(`[data-controller*="note-edit"]`) === this.element
    
    if (!isOurForm && !isFromOurController) {
      // Not our form, ignore
      return
    }
    
    // Check response status
    const fetchResponse = event.detail?.fetchResponse
    const response = fetchResponse?.response
    
    if (response) {
      if (response.ok) {
        // Success - Turbo Stream will update the DOM
        // Wait for Turbo Stream to process before resetting state
        // Turbo Stream updates happen asynchronously, so we need to wait
        this.waitForTurboStreamUpdate(() => {
          this.isSubmitting = false
          this.isEditing = false
          this.enableFormButtons()
          this.clearErrors()
          // Display mode will be shown by Turbo Stream updating the note item
        })
      } else {
        // Error - keep edit mode active so user can correct
        this.isSubmitting = false
        this.enableFormButtons()
        // Errors will be displayed by the server response via Turbo Stream
        // The note item will be re-rendered with errors
      }
    } else {
      // No response (network error, etc.)
      this.isSubmitting = false
      this.enableFormButtons()
      this.showError("Network error. Please try again.")
    }
  }

  // Wait for Turbo Stream to update the DOM
  waitForTurboStreamUpdate(callback, maxWait = 500) {
    const startTime = Date.now()
    const checkInterval = 50
    
    const checkForUpdate = () => {
      // Check if the note item has been updated (display mode should be visible)
      const displayMode = this.displayModeTarget
      const isUpdated = displayMode && !displayMode.classList.contains('hidden')
      
      if (isUpdated || (Date.now() - startTime) > maxWait) {
        callback()
      } else {
        setTimeout(checkForUpdate, checkInterval)
      }
    }
    
    // Start checking after a brief delay to allow Turbo Stream to start processing
    setTimeout(checkForUpdate, 50)
  }

  // Delete note with confirmation
  delete(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.isSubmitting || this.isEditing) return
    
    // Show confirmation dialog
    const confirmed = confirm("Are you sure you want to delete this note? This action cannot be undone.")
    
    if (!confirmed) {
      return
    }
    
    // Find the delete form (button_to creates a form)
    const deleteButton = event.currentTarget
    const deleteForm = deleteButton.closest('form')
    
    if (deleteForm) {
      // Disable button during submission
      this.isSubmitting = true
      if (this.hasDeleteButtonTarget) {
        this.deleteButtonTarget.disabled = true
        this.deleteButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
      }
      
      // Add loading state to button text
      const buttonText = deleteButton.querySelector('svg')?.nextSibling
      if (buttonText && buttonText.nodeType === Node.TEXT_NODE) {
        deleteButton.dataset.originalText = buttonText.textContent
        buttonText.textContent = 'Deleting...'
      }
      
      // Submit the delete request via Turbo
      // Turbo Stream will remove the element on success
      deleteForm.requestSubmit()
      
      // Reset state after a delay in case of error
      setTimeout(() => {
        if (this.isSubmitting) {
          this.isSubmitting = false
          if (this.hasDeleteButtonTarget) {
            this.deleteButtonTarget.disabled = false
            this.deleteButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
            const buttonText = this.deleteButtonTarget.querySelector('svg')?.nextSibling
            if (buttonText && buttonText.nodeType === Node.TEXT_NODE && deleteButton.dataset.originalText) {
              buttonText.textContent = deleteButton.dataset.originalText
            }
          }
        }
      }, 5000) // Reset after 5 seconds if no response
    }
  }

  // Show display mode, hide edit mode
  showDisplayMode() {
    if (this.hasDisplayModeTarget) {
      this.displayModeTarget.classList.remove('hidden')
      this.displayModeTarget.setAttribute('aria-hidden', 'false')
    }
  }

  hideDisplayMode() {
    if (this.hasDisplayModeTarget) {
      this.displayModeTarget.classList.add('hidden')
      this.displayModeTarget.setAttribute('aria-hidden', 'true')
    }
  }

  // Show edit mode, hide display mode
  showEditMode() {
    if (this.hasEditModeTarget) {
      this.editModeTarget.classList.remove('hidden')
      this.editModeTarget.setAttribute('aria-hidden', 'false')
    }
  }

  hideEditMode() {
    if (this.hasEditModeTarget) {
      this.editModeTarget.classList.add('hidden')
      this.editModeTarget.setAttribute('aria-hidden', 'true')
    }
  }

  // Form button management
  disableFormButtons() {
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = true
      // Store original text
      const originalText = this.saveButtonTarget.textContent.trim()
      if (originalText && originalText !== 'Saving...') {
        this.saveButtonTarget.dataset.originalText = originalText
      }
      this.saveButtonTarget.textContent = 'Saving...'
      this.saveButtonTarget.classList.add('opacity-75')
    }
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.disabled = true
      this.cancelButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    }
  }

  enableFormButtons() {
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = false
      // Restore original text
      if (this.saveButtonTarget.dataset.originalText) {
        this.saveButtonTarget.textContent = this.saveButtonTarget.dataset.originalText
        delete this.saveButtonTarget.dataset.originalText
      }
      this.saveButtonTarget.classList.remove('opacity-75')
    }
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.disabled = false
      this.cancelButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    }
  }

  // Error handling
  showError(message) {
    // Find or create error container
    let errorContainer = this.editModeTarget?.querySelector('[data-note-edit-target="errorContainer"]')
    
    if (!errorContainer && this.hasEditModeTarget) {
      errorContainer = document.createElement('div')
      errorContainer.setAttribute('data-note-edit-target', 'errorContainer')
      errorContainer.className = 'mt-2 text-sm text-red-600'
      
      // Insert after textarea
      if (this.hasTextareaTarget) {
        this.textareaTarget.parentElement.appendChild(errorContainer)
      }
    }
    
    if (errorContainer) {
      errorContainer.textContent = message
      errorContainer.classList.remove('hidden')
    }
  }

  clearErrors() {
    const errorContainer = this.editModeTarget?.querySelector('[data-note-edit-target="errorContainer"]')
    if (errorContainer) {
      errorContainer.textContent = ''
      errorContainer.classList.add('hidden')
    }
    
    // Also clear any server-side error messages
    const serverErrors = this.editModeTarget?.querySelectorAll('.text-red-600, .error-message')
    if (serverErrors) {
      serverErrors.forEach(error => {
        error.textContent = ''
        error.classList.add('hidden')
      })
    }
  }
}

