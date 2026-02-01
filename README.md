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
- [Running Tests](#running-tests)
- [Available Scripts](#available-scripts)
- [CI/CD](#cicd)
- [Troubleshooting](#troubleshooting)
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
| **Backend**       | Ruby on Rails 8.0, Puma                          |
| **Frontend**      | Hotwire (Turbo, Stimulus), Tailwind CSS, Importmap|
| **Database**      | PostgreSQL 17                                    |
| **Authentication**| Devise                                           |
| **AI Integration**| OpenRouter.ai (GPT-4o-mini)                      |
| **Testing**       | RSpec, Capybara, Selenium                        |
| **Code Quality**  | RuboCop, Brakeman, SimpleCov                     |
| **Type Safety**   | Sorbet, Tapioca                                  |
| **Deployment**    | Docker, Kamal, DigitalOcean                      |
| **CI/CD**         | GitHub Actions                                   |

### Key Dependencies
- **Blueprinter**: JSON serialization
- **Pagy**: Pagination
- **FactoryBot**: Test data generation
- **WebMock**: HTTP request stubbing for tests

---

## Getting Started Locally

Follow these instructions to set up the project on your local machine for development and testing.

> **💡 First Time with Ruby?** Don't worry! We'll guide you through installing Ruby using asdf, a popular version manager that makes it easy to work with Ruby projects.

### Prerequisites

#### Ruby Setup with asdf (Recommended)

If you don't have Ruby installed, we recommend using [asdf](https://asdf-vm.com/) for version management. It allows you to easily switch between Ruby versions.

**1. Install asdf:**

<details>
<summary><strong>macOS</strong></summary>

```sh
# Using Homebrew
brew install asdf

# Add to your shell profile (~/.zshrc or ~/.bash_profile)
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
# Restart your terminal or run:
source ~/.zshrc
```
</details>

<details>
<summary><strong>Linux (Ubuntu/Debian)</strong></summary>

```sh
# Clone asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

# Add to your shell profile (~/.bashrc or ~/.zshrc)
echo -e '\n. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo -e '\n. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
# Restart your terminal or run:
source ~/.bashrc
```
</details>

**2. Install Ruby plugin and dependencies:**

```sh
# Add the Ruby plugin to asdf
asdf plugin add ruby

# Install Ruby dependencies (macOS)
brew install openssl readline libyaml gmp

# Install Ruby dependencies (Ubuntu/Debian)
sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev
```

**3. Install the project's Ruby version:**

```sh
# This will automatically install the version specified in .ruby-version
asdf install ruby

# Set it as the default version for this project
asdf local ruby 3.4.4
```

**4. Verify Ruby installation:**

```sh
ruby -v
# Should output: ruby 3.4.4

which ruby
# Should show asdf path
```

<details>
<summary><strong>Alternative: Using rbenv or RVM</strong></summary>

If you prefer other Ruby version managers:

**rbenv:**
```sh
# Install rbenv
brew install rbenv  # macOS
# or follow: https://github.com/rbenv/rbenv#installation

# Install Ruby
rbenv install 3.4.4
rbenv local 3.4.4
```

**RVM:**
```sh
# Install RVM
\curl -sSL https://get.rvm.io | bash -s stable

# Install Ruby
rvm install 3.4.4
rvm use 3.4.4
```
</details>

#### Other Required Software

Make sure you also have the following installed:
- **Rails**: `~> 8.0.2` (will be installed via bundler)
- **Node.js**: `~> 20.x` (for the asset pipeline)
  - With asdf: `asdf plugin add nodejs && asdf install nodejs 20.11.0`
  - With Homebrew: `brew install node@20`
- **PostgreSQL**: `~> 17.x`
  - With Homebrew: `brew install postgresql@17`
  - With apt: `sudo apt-get install postgresql-17`
- **Docker** (optional, for containerized setup)

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
    
    Rails 8 uses encrypted credentials. For development, you'll need to set up:
    
    ```sh
    # Generate a new master key if you don't have one
    # This will create config/master.key
    EDITOR="nano" bin/rails credentials:edit
    ```
    
    Add the following to your credentials:
    ```yaml
    openrouter:
      api_key: your_openrouter_api_key_here
    
    # Optional: Configure email settings for Devise
    # smtp:
    #   address: smtp.gmail.com
    #   port: 587
    #   user_name: your_email@gmail.com
    #   password: your_app_password
    ```
    
    **Note**: Never commit `config/master.key` to version control.

4.  **Create and set up the database:**
    ```sh
    bin/rails db:create
    bin/rails db:migrate
    bin/rails db:seed
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
-   `bin/rails spec`: Runs the full automated test suite.
-   `bundle exec rspec spec/system`: Runs E2E/system tests only.
-   `bundle exec rspec --tag ~type:system`: Runs unit tests only (excludes system tests).
-   `bin/rubocop`: Lints the codebase for style consistency.
-   `bin/brakeman`: Runs a static analysis for security vulnerabilities.

---

## Running Tests

### Full Test Suite
```sh
bundle exec rspec
```

### Unit Tests Only
```sh
bundle exec rspec --tag ~type:system
```

### E2E/System Tests Only
```sh
# Headless mode (default)
bundle exec rspec spec/system

# With visible browser (for debugging)
HEADFUL=1 bundle exec rspec spec/system
```

**Note**: System tests use Selenium with Chrome. Chrome will be installed automatically in CI, but for local development, you need Chrome installed on your system.

### Test Coverage
Test coverage reports are generated in the `coverage/` directory after running tests. Open `coverage/index.html` in your browser to view the report.

---

## CI/CD

The project uses GitHub Actions for continuous integration. The pipeline includes:

- **Linting**: Code style checks with RuboCop
- **Security Scanning**: Brakeman (Ruby) and Importmap audit (JavaScript)
- **Unit Tests**: Fast tests excluding system tests
- **E2E Tests**: System tests with Selenium and headless Chrome

All tests run automatically on pull requests and pushes to the main branch.

---

## Troubleshooting

### Database Connection Issues
If you encounter database connection errors:
```sh
# Check PostgreSQL is running
# On macOS with Homebrew:
brew services list

# Start PostgreSQL if not running:
brew services start postgresql@17
```

### Missing Chrome for E2E Tests
System tests require Chrome to be installed:
```sh
# On macOS:
brew install --cask google-chrome

# On Ubuntu/Debian:
sudo apt-get install google-chrome-stable
```

### Bundle Install Errors
If you encounter native extension compilation errors:
```sh
# On macOS, ensure Xcode Command Line Tools are installed:
xcode-select --install

# On Ubuntu/Debian:
sudo apt-get install build-essential libpq-dev
```

### Port Already in Use
If port 3000 is already in use:
```sh
# Find the process using the port
lsof -i :3000

# Kill the process (replace PID with actual process ID)
kill -9 PID

# Or use a different port
bin/rails server -p 3001
```

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
