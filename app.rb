require 'sinatra/base'
require 'rack/protection'

# Completely disable Rack protection modules that might block requests
class RealtyMonsterApp < Sinatra::Base
  # Disable protection to allow access in Replit environment
  disable :protection
  set :protection, false
  
  # Configure for Repl.it environment
  set :bind, '0.0.0.0'
  set :port, 5000
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :views, File.dirname(__FILE__) + '/views'
  
  # Routes
  
  # Home page - just a simple response for testing
  get '/' do
    "Hello from RealtyMonster! The application is working correctly. More features coming soon."
  end
  
  # Route to test JSON
  get '/api/test' do
    content_type :json
    { status: 'ok', message: 'API is working' }.to_json
  end
  
  # Start the server if this file is run directly
  run! if app_file == $0
end