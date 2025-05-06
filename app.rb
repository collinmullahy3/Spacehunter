require 'sinatra/base'
require 'sinatra/content_for'
require 'json'
require 'erb'

class RealtyMonsterApp < Sinatra::Base
  helpers Sinatra::ContentFor
  
  # Enable sessions and set configurations
  enable :sessions
  set :session_secret, "realty_monster_secret"
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :views, File.dirname(__FILE__) + '/views'
  
  # Helper methods
  helpers do
    # HTML escaping
    def h(text)
      Rack::Utils.escape_html(text)
    end
    
    # Format price with commas
    def number_with_precision(number)
      number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
  
  # Sample apartments data (in-memory database)
  before do
    @apartments = [
      {
        id: 1,
        title: "Luxurious Downtown Penthouse",
        description: "Experience luxury living in this stunning downtown penthouse with panoramic city views. This spacious 3-bedroom apartment features high-end finishes, a gourmet kitchen with stainless steel appliances, and a private balcony perfect for entertaining.",
        price: 3500,
        bedrooms: 3,
        bathrooms: 2,
        square_feet: 1800,
        address: "123 Main Street",
        city: "New York",
        state: "NY",
        zip: "10001",
        available_date: "2023-10-01"
      },
      {
        id: 2,
        title: "Cozy Studio in Historic District",
        description: "Charming studio apartment in the heart of the historic district. This recently renovated unit features hardwood floors, exposed brick walls, and modern fixtures. Walking distance to shops, restaurants, and public transportation.",
        price: 1200,
        bedrooms: 0,
        bathrooms: 1,
        square_feet: 550,
        address: "456 Elm Street",
        city: "Boston",
        state: "MA",
        zip: "02108",
        available_date: "2023-09-15"
      },
      {
        id: 3,
        title: "Modern 2-Bedroom with City View",
        description: "Stunning 2-bedroom apartment with floor-to-ceiling windows offering breathtaking city views. This contemporary unit features an open floor plan, high-end finishes, and a state-of-the-art kitchen. Building amenities include a fitness center, rooftop pool, and 24-hour concierge.",
        price: 2800,
        bedrooms: 2,
        bathrooms: 2,
        square_feet: 1200,
        address: "789 Oak Avenue",
        city: "San Francisco",
        state: "CA",
        zip: "94102",
        available_date: "2023-09-30"
      },
      {
        id: 4,
        title: "Spacious Family Apartment",
        description: "Perfect for families, this spacious 4-bedroom apartment offers ample living space and a convenient location. Features include a large kitchen, separate dining area, and in-unit laundry. Located near schools, parks, and shopping centers.",
        price: 2200,
        bedrooms: 4,
        bathrooms: 2,
        square_feet: 1600,
        address: "101 Pine Street",
        city: "Chicago",
        state: "IL",
        zip: "60601",
        available_date: "2023-10-15"
      },
      {
        id: 5,
        title: "Stylish 1-Bedroom in Art District",
        description: "Chic 1-bedroom apartment in the vibrant Art District. This stylishly furnished unit features contemporary décor, high ceilings, and modern amenities. Enjoy the neighborhood's galleries, cafes, and boutiques just steps from your door.",
        price: 1800,
        bedrooms: 1,
        bathrooms: 1,
        square_feet: 750,
        address: "222 Gallery Way",
        city: "Los Angeles",
        state: "CA",
        zip: "90012",
        available_date: "2023-09-15"
      }
    ]
  end
  
  # Routes
  
  # Home page
  get '/' do
    @featured_apartments = @apartments.sample(3)
    erb :home
  end
  
  # Apartments index
  get '/apartments' do
    erb :apartment_index
  end
  
  # Show apartment details
  get '/apartments/:id' do
    id = params[:id].to_i
    @apartment = @apartments.find { |a| a[:id] == id }
    
    if @apartment
      erb :apartment_show
    else
      status 404
      "Apartment not found"
    end
  end
  
  # Start the server if the file is run directly
  run! if app_file == $0
end