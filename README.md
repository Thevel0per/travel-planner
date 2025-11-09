# TravelPlanner

[![Project Status: In Development](https://img.shields.io/badge/status-in%20development-orange.svg)](https://github.com/Thevel0per/travel-planner)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An AI-powered travel planning application designed to simplify the process of creating engaging and personalized trips.

---

## Table of Contents

- [Project Description](#project-description)
- [Tech Stack](#tech-stack)
- [Getting Started Locally](#getting-started-locally)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Available Scripts](#available-scripts)
- [Project Scope](#project-scope)
  - [In Scope for MVP](#in-scope-for-mvp)
  - [Out of Scope for MVP](#out-of-scope-for-mvp)
- [Project Status](#project-status)
- [License](#license)

---

## Project Description

**TravelPlanner** is an AI-powered travel planning application that transforms users' simple notes and preferences into detailed, structured travel itineraries. The application leverages AI to address the common challenges of travel planning, which can be time-consuming and overwhelming. By converting scattered ideas into a coherent and personalized plan, TravelPlanner helps users save time and create trips that better match their expectations.

### Key Features
- **User Account Management**: Secure registration, login, email verification, and password reset.
- **Trip and Note Management**: Full CRUD functionality for managing trips and associated text notes.
- **User Preference Profile**: A dedicated section for users to define their travel style, including budget, accommodation, activities, and eating habits.
- **AI-Powered Plan Generation**: Generates detailed travel plans based on user notes and preferences using AI models accessed via OpenRouter.ai.
- **Detailed Plan Output**: Presents plans in a clear format, including activities, estimated costs, ratings, and restaurant suggestions.
- **User Feedback**: Allows users to rate generated plans to help improve the service.

---

## Tech Stack

The project is built with a modern Ruby on Rails stack:

| Category          | Technology                                       |
|-------------------|--------------------------------------------------|
| **Backend**       | Ruby on Rails 8, Puma                            |
| **Frontend**      | Hotwire (Turbo, Stimulus), Tailwind CSS, Importmap|
| **Database**      | PostgreSQL                                       |
| **Authentication**| Devise                                           |
| **AI Integration**| OpenRouter.ai                                    |
| **Testing**       | RSpec                                            |
| **Deployment**    | Docker, Kamal, DigitalOcean                      |
| **CI/CD**         | GitHub Actions                                   |

---

## Getting Started Locally

Follow these instructions to set up the project on your local machine for development and testing.

### Prerequisites

Make sure you have the following software installed on your system:
- **Ruby**: `~> 3.2.2`
- **Rails**: `~> 8.0.2`
- **Node.js**: `~> 20.x` (for the asset pipeline)
- **PostgreSQL**: `~> 14.x`
- **Docker** (optional, for a containerized setup)

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/Thevel0per/travel-planner.git
    cd travel-planner
    ```

2.  **Install dependencies:**
    ```sh
    bundle install
    ```

3.  **Set up environment variables:**
    Create a `.env` file in the project root by copying the example file:
    ```sh
    cp .env.example .env
    ```
    Update the `.env` file with your local database credentials and any necessary API keys (e.g., `OPENROUTER_API_KEY`).

4.  **Create and set up the database:**
    ```sh
    rails db:create
    rails db:migrate
    rails db:seed
    ```

5.  **Start the development server:**
    ```sh
    bin/dev
    ```
    The application will be available at `http://localhost:3000`.

---

## Available Scripts

This project includes several scripts to help with development:

-   `bin/dev`: Starts the development server (Rails server, CSS watcher, etc.).
-   `bin/rails spec`: Runs the automated test suite.
-   `bin/rubocop`: Lints the codebase for style consistency.
-   `bin/brakeman`: Runs a static analysis for security vulnerabilities.

---

## Project Scope

The initial version (MVP) of TravelPlanner focuses on core functionalities.

### In Scope for MVP
- ✅ User accounts with email/password authentication.
- ✅ Full CRUD operations for trips and associated text notes.
- ✅ User profile with predefined preference categories.
- ✅ AI plan generation based on user notes and preferences.
- ✅ Support for leisure trips only.
- ✅ English language support only.
- ✅ Simple email service integration for notifications.

### Out of Scope for MVP
- ❌ Sharing travel plans between users.
- ❌ Rich multimedia handling (e.g., uploading photos).
- ❌ Advanced logistics or booking integrations.
- ❌ Verification of AI-generated data (costs, ratings, etc.).
- ❌ Automated handling of AI generation failures.
- ❌ Using user feedback to automatically fine-tune the AI model.
- ❌ Support for business trips.
- ❌ Multi-language support.

---

## Project Status

This project is currently **in the development phase** for the Minimum Viable Product (MVP). It is not yet ready for production use.

Future work will focus on implementing the features listed in the "Out of Scope for MVP" section and refining the user experience.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
