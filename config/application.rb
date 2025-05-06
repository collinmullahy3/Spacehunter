require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RealtyMonster
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set time zone
    config.time_zone = 'UTC'

    # Don't generate system test files.
    config.generators.system_tests = nil
    
    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]
    
    # For the asset pipeline
    config.assets.enabled = true
    config.assets.version = '1.0'
    
    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true
  end
end