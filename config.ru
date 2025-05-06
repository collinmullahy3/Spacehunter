require './app'

# Set up any middleware here
use Rack::Static, :urls => ["/css", "/js", "/images", "/favicon.ico"], :root => "public"

# Disable host authorization to allow connections in Repl.it
# This needs to happen at the Rack middleware level
class AllowAnyHost
  def initialize(app)
    @app = app
  end
  
  def call(env)
    # Don't check the Host header, just pass through
    @app.call(env)
  end
end

use AllowAnyHost

# Run our application
run RealtyMonsterApp