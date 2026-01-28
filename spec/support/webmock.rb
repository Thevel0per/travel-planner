# frozen_string_literal: true

# Only load WebMock if it's already been required by a spec
if defined?(WebMock)
  # Allow connections to localhost and 127.0.0.1 for browser automation (Cuprite/Selenium)
  # These are used by the headless browser driver to communicate with Chrome
  WebMock.disable_net_connect!(
    allow_localhost: true,
    allow: [
      /127\.0\.0\.1/,
      /localhost/
    ]
  )
end
