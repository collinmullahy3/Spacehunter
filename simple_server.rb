require 'socket'
require 'uri'
require 'json'

# In-memory database for apartments
APARTMENTS = [
  {
    id: 1,
    title: "Luxurious Downtown Penthouse",
    location: "123 Main Street, New York, NY 10001",
    price: 3500,
    bedrooms: 3,
    bathrooms: 2,
    square_feet: 1800,
    description: "Experience luxury living in this stunning downtown penthouse with panoramic city views. This spacious 3-bedroom apartment features high-end finishes, a gourmet kitchen with stainless steel appliances, and a private balcony perfect for entertaining.",
    features: ["Hardwood flooring throughout", "Floor-to-ceiling windows", "Central air conditioning", "In-unit washer and dryer", "24-hour doorman", "Fitness center access"],
    available_from: "October 1, 2023",
    neighborhood: "Downtown",
    pet_friendly: true,
    parking: "Available for $250/month",
    image_url: "/images/apt1.jpg" # Would point to an actual image if we had one
  },
  {
    id: 2,
    title: "Cozy Midtown Studio",
    location: "456 Park Avenue, New York, NY 10022",
    price: 1800,
    bedrooms: 0,
    bathrooms: 1,
    square_feet: 550,
    description: "Perfectly located studio apartment in the heart of Midtown. This recently renovated unit features modern finishes, ample storage space, and large windows that flood the space with natural light.",
    features: ["Stainless steel appliances", "Hardwood floors", "Large windows", "Updated bathroom", "Rooftop access", "Laundry in building"],
    available_from: "September 15, 2023",
    neighborhood: "Midtown",
    pet_friendly: false,
    parking: "Street parking only",
    image_url: "/images/apt2.jpg"
  },
  {
    id: 3,
    title: "Spacious Brooklyn Brownstone",
    location: "789 Greene Avenue, Brooklyn, NY 11221",
    price: 2800,
    bedrooms: 2,
    bathrooms: 1.5,
    square_feet: 1200,
    description: "Charming brownstone apartment in Brooklyn's vibrant Bedford-Stuyvesant neighborhood. This 2-bedroom unit offers a perfect blend of historic charm and modern convenience with its original hardwood floors, decorative fireplace, and updated kitchen.",
    features: ["Original hardwood floors", "Decorative fireplace", "High ceilings", "Updated kitchen", "Private backyard access", "Basement storage"],
    available_from: "August 1, 2023",
    neighborhood: "Bedford-Stuyvesant",
    pet_friendly: true,
    parking: "Garage available for $200/month",
    image_url: "/images/apt3.jpg"
  },
  {
    id: 4,
    title: "Modern East Village 1 Bedroom",
    location: "321 East 4th Street, New York, NY 10009",
    price: 2400,
    bedrooms: 1,
    bathrooms: 1,
    square_feet: 700,
    description: "Stylish one-bedroom apartment in the trendy East Village. Recently renovated with sleek finishes, this unit offers an open concept living area, chef's kitchen with breakfast bar, and a spacious bedroom with custom closets.",
    features: ["Chef's kitchen", "Custom closets", "Open floor plan", "Recessed lighting", "Built-in bookshelves", "Bicycle storage"],
    available_from: "July 15, 2023",
    neighborhood: "East Village",
    pet_friendly: true,
    parking: "None",
    image_url: "/images/apt4.jpg"
  },
  {
    id: 5,
    title: "Upper West Side Classic",
    location: "543 West 86th Street, New York, NY 10024",
    price: 4200,
    bedrooms: 3,
    bathrooms: 2,
    square_feet: 1500,
    description: "Elegant pre-war apartment on the Upper West Side. This spacious 3-bedroom home features classic architectural details including high ceilings, crown moldings, and a formal dining room, all just steps from Central Park.",
    features: ["Pre-war details", "Formal dining room", "Large eat-in kitchen", "Crown moldings", "Elevator building", "Live-in super"],
    available_from: "September 1, 2023",
    neighborhood: "Upper West Side",
    pet_friendly: true,
    parking: "Garage in building",
    image_url: "/images/apt5.jpg"
  }
]

# Helper method to parse query parameters
def parse_query_params(query_string)
  return {} if query_string.nil? || query_string.empty?
  
  params = {}
  query_string.split('&').each do |pair|
    key, value = pair.split('=')
    params[URI.decode_www_form_component(key)] = URI.decode_www_form_component(value)
  end
  params
end

# Helper method to filter apartments
def filter_apartments(params)
  filtered = APARTMENTS
  
  # Filter by min bedrooms
  if params['min_bedrooms'] && !params['min_bedrooms'].empty?
    min_beds = params['min_bedrooms'].to_i
    filtered = filtered.select { |apt| apt[:bedrooms] >= min_beds }
  end
  
  # Filter by max price
  if params['max_price'] && !params['max_price'].empty?
    max_price = params['max_price'].to_i
    filtered = filtered.select { |apt| apt[:price] <= max_price }
  end
  
  # Filter by neighborhood
  if params['neighborhood'] && !params['neighborhood'].empty?
    neighborhood = params['neighborhood'].downcase
    filtered = filtered.select { |apt| apt[:neighborhood].downcase.include?(neighborhood) }
  end
  
  # Filter by pet friendly
  if params['pet_friendly'] == 'true'
    filtered = filtered.select { |apt| apt[:pet_friendly] }
  end
  
  filtered
end

# Create a simple TCP server that responds to HTTP requests
server = TCPServer.new('0.0.0.0', 5000)
puts "Server started at http://0.0.0.0:5000"

loop do
  client = server.accept
  request_line = client.readline
  
  puts "Received request: #{request_line}"
  
  method, full_path, http_version = request_line.split
  
  # Parse the path and query string
  path, query_string = full_path.split('?')
  path = URI.decode_www_form_component(path)
  query_params = parse_query_params(query_string || '')
  
  # Read all HTTP headers
  headers = {}
  while true
    line = client.readline.strip
    break if line.empty?
    name, value = line.split(': ', 2)
    headers[name] = value
  end
  
  # Set up the response
  if path == "/"
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>RealtyMonster - Apartment Search</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #333; }
    h1, h2, h3 { color: #2c3e50; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #34495e; color: white; padding: 20px 0; margin-bottom: 30px; }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 24px; font-weight: bold; }
    .search-container { background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
    .form-group { margin-bottom: 15px; }
    .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
    .form-group input, .form-group select { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
    .form-row { display: flex; gap: 15px; }
    .form-row .form-group { flex: 1; }
    .btn { display: inline-block; background: #3498db; color: white; padding: 10px 15px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; }
    .btn:hover { background: #2980b9; }
    .btn-search { background: #27ae60; }
    .btn-search:hover { background: #219653; }
    .btn-reset { background: #e74c3c; }
    .btn-reset:hover { background: #c0392b; }
    .apartments-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 20px; }
    .apartment-card { border: 1px solid #ddd; border-radius: 8px; overflow: hidden; transition: transform 0.3s; }
    .apartment-card:hover { transform: translateY(-5px); box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
    .apartment-img { height: 200px; background-color: #ddd; background-position: center; background-size: cover; }
    .apartment-details { padding: 20px; }
    .apartment-price { font-size: 22px; font-weight: bold; color: #27ae60; margin-bottom: 10px; }
    .apartment-location { color: #7f8c8d; margin-bottom: 15px; }
    .apartment-features { display: flex; gap: 15px; margin-bottom: 15px; }
    .apartment-feature { display: flex; align-items: center; }
    .apartment-feature span { margin-left: 5px; }
    .footer { background-color: #34495e; color: white; padding: 30px 0; margin-top: 50px; }
    .checkbox-group { display: flex; align-items: center; }
    .checkbox-group input { width: auto; margin-right: 10px; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'>RealtyMonster</div>
    </div>
  </header>
  
  <div class='container'>
    <h1>Find Your Perfect Apartment</h1>
    
    <div class='search-container'>
      <form action='/' method='get'>
        <div class='form-row'>
          <div class='form-group'>
            <label for='neighborhood'>Neighborhood</label>
            <input type='text' id='neighborhood' name='neighborhood' placeholder='E.g. Downtown, Midtown, etc.' value='#{query_params['neighborhood'] || ''}'>
          </div>
          <div class='form-group'>
            <label for='min_bedrooms'>Minimum Bedrooms</label>
            <select id='min_bedrooms' name='min_bedrooms'>
              <option value='' #{query_params['min_bedrooms'].nil? || query_params['min_bedrooms'].empty? ? 'selected' : ''}>Any</option>
              <option value='0' #{query_params['min_bedrooms'] == '0' ? 'selected' : ''}>Studio</option>
              <option value='1' #{query_params['min_bedrooms'] == '1' ? 'selected' : ''}>1+ Bedrooms</option>
              <option value='2' #{query_params['min_bedrooms'] == '2' ? 'selected' : ''}>2+ Bedrooms</option>
              <option value='3' #{query_params['min_bedrooms'] == '3' ? 'selected' : ''}>3+ Bedrooms</option>
            </select>
          </div>
          <div class='form-group'>
            <label for='max_price'>Maximum Price</label>
            <input type='number' id='max_price' name='max_price' placeholder='Enter maximum monthly rent' value='#{query_params['max_price'] || ''}'>
          </div>
        </div>
        
        <div class='form-row'>
          <div class='form-group checkbox-group'>
            <input type='checkbox' id='pet_friendly' name='pet_friendly' value='true' #{query_params['pet_friendly'] == 'true' ? 'checked' : ''}>
            <label for='pet_friendly'>Pet Friendly</label>
          </div>
        </div>
        
        <div class='form-row'>
          <button type='submit' class='btn btn-search'>Search</button>
          <a href='/' class='btn btn-reset'>Reset</a>
        </div>
      </form>
    </div>
    
    <h2>Available Apartments</h2>
    
    <div class='apartments-grid'>"
    
    # Filter apartments based on query parameters
    apartments = filter_apartments(query_params)
    
    if apartments.empty?
      response_content += "
      <div style='grid-column: 1 / -1; text-align: center; padding: 30px;'>
        <h3>No apartments match your search criteria</h3>
        <p>Try adjusting your filters or <a href='/'>view all apartments</a>.</p>
      </div>"
    else
      apartments.each do |apt|
        response_content += "
        <div class='apartment-card'>
          <div class='apartment-img' style='background-color: #3498db;'></div>
          <div class='apartment-details'>
            <h3>#{apt[:title]}</h3>
            <div class='apartment-price'>$#{apt[:price]}/month</div>
            <div class='apartment-location'>#{apt[:location]}</div>
            <div class='apartment-features'>
              <div class='apartment-feature'>
                <strong>#{apt[:bedrooms] == 0 ? 'Studio' : "#{apt[:bedrooms]} BR"}</strong>
              </div>
              <div class='apartment-feature'>
                <strong>#{apt[:bathrooms]} Bath</strong>
              </div>
              <div class='apartment-feature'>
                <strong>#{apt[:square_feet]} sq ft</strong>
              </div>
            </div>
            <p>#{apt[:description][0..100]}...</p>
            <a href='/apartments/#{apt[:id]}' class='btn'>View Details</a>
          </div>
        </div>"
      end
    end
    
    response_content += "
    </div>
  </div>
  
  <footer class='footer'>
    <div class='container'>
      <p>&copy; 2025 RealtyMonster. All rights reserved.</p>
    </div>
  </footer>
</body>
</html>"
  elsif path.start_with?("/apartments/")
    # Extract apartment ID from the path
    apartment_id = path.split('/').last.to_i
    apartment = APARTMENTS.find { |apt| apt[:id] == apartment_id }
    
    if apartment
      response_content = "<!DOCTYPE html>
<html>
<head>
  <title>#{apartment[:title]} - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #333; }
    h1, h2, h3 { color: #2c3e50; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #34495e; color: white; padding: 20px 0; margin-bottom: 30px; }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 24px; font-weight: bold; }
    .back-link { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; }
    .back-link:hover { text-decoration: underline; }
    .apartment-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; }
    .apartment-title h1 { margin: 0; }
    .apartment-price { font-size: 28px; font-weight: bold; color: #27ae60; }
    .apartment-image { height: 400px; background-color: #3498db; border-radius: 8px; margin-bottom: 30px; }
    .apartment-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 30px; }
    .apartment-details { background-color: #f8f9fa; padding: 20px; border-radius: 8px; }
    .apartment-feature-list { list-style-type: none; padding: 0; }
    .apartment-feature-list li { margin-bottom: 10px; padding-left: 25px; position: relative; }
    .apartment-feature-list li:before { content: '✓'; position: absolute; left: 0; color: #27ae60; font-weight: bold; }
    .contact-form { background-color: #f8f9fa; padding: 20px; border-radius: 8px; }
    .form-group { margin-bottom: 15px; }
    .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
    .form-group input, .form-group textarea { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
    .btn { display: inline-block; background: #3498db; color: white; padding: 10px 15px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; }
    .btn:hover { background: #2980b9; }
    .footer { background-color: #34495e; color: white; padding: 30px 0; margin-top: 50px; }
    .property-info { display: flex; flex-wrap: wrap; gap: 15px; margin-bottom: 20px; }
    .property-info-item { flex: 1; min-width: 150px; background-color: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .property-info-item strong { display: block; margin-bottom: 5px; font-size: 14px; color: #7f8c8d; }
    .property-info-item span { font-size: 18px; font-weight: bold; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'>RealtyMonster</div>
    </div>
  </header>
  
  <div class='container'>
    <a href='/' class='back-link'>&larr; Back to all apartments</a>
    
    <div class='apartment-header'>
      <div class='apartment-title'>
        <h1>#{apartment[:title]}</h1>
        <div>#{apartment[:location]}</div>
      </div>
      <div class='apartment-price'>$#{apartment[:price]}/month</div>
    </div>
    
    <div class='apartment-image'></div>
    
    <div class='apartment-grid'>
      <div>
        <div class='property-info'>
          <div class='property-info-item'>
            <strong>Bedrooms</strong>
            <span>#{apartment[:bedrooms] == 0 ? 'Studio' : apartment[:bedrooms]}</span>
          </div>
          <div class='property-info-item'>
            <strong>Bathrooms</strong>
            <span>#{apartment[:bathrooms]}</span>
          </div>
          <div class='property-info-item'>
            <strong>Square Feet</strong>
            <span>#{apartment[:square_feet]}</span>
          </div>
          <div class='property-info-item'>
            <strong>Available From</strong>
            <span>#{apartment[:available_from]}</span>
          </div>
          <div class='property-info-item'>
            <strong>Pet Friendly</strong>
            <span>#{apartment[:pet_friendly] ? 'Yes' : 'No'}</span>
          </div>
          <div class='property-info-item'>
            <strong>Parking</strong>
            <span>#{apartment[:parking]}</span>
          </div>
        </div>
        
        <h2>Description</h2>
        <p>#{apartment[:description]}</p>
        
        <h2>Features</h2>
        <ul class='apartment-feature-list'>
          #{apartment[:features].map { |feature| "<li>#{feature}</li>" }.join("\n          ")}
        </ul>
      </div>
      
      <div>
        <div class='contact-form'>
          <h3>Schedule a Showing</h3>
          <form action='/schedule' method='post'>
            <input type='hidden' name='apartment_id' value='#{apartment[:id]}'>
            <div class='form-group'>
              <label for='name'>Your Name</label>
              <input type='text' id='name' name='name' required>
            </div>
            <div class='form-group'>
              <label for='email'>Email Address</label>
              <input type='email' id='email' name='email' required>
            </div>
            <div class='form-group'>
              <label for='phone'>Phone Number</label>
              <input type='tel' id='phone' name='phone'>
            </div>
            <div class='form-group'>
              <label for='date'>Preferred Date</label>
              <input type='date' id='date' name='date' required>
            </div>
            <div class='form-group'>
              <label for='message'>Additional Information</label>
              <textarea id='message' name='message' rows='4'></textarea>
            </div>
            <button type='submit' class='btn'>Request Showing</button>
          </form>
        </div>
      </div>
    </div>
  </div>
  
  <footer class='footer'>
    <div class='container'>
      <p>&copy; 2025 RealtyMonster. All rights reserved.</p>
    </div>
  </footer>
</body>
</html>"
    else
      # Apartment not found
      response_content = "<!DOCTYPE html>
<html>
<head>
  <title>Apartment Not Found - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #333; text-align: center; }
    h1 { color: #e74c3c; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .btn { display: inline-block; background: #3498db; color: white; padding: 10px 15px; 
           text-decoration: none; border-radius: 4px; margin-top: 20px; }
    .header { background-color: #34495e; color: white; padding: 20px 0; margin-bottom: 30px; }
    .logo { font-size: 24px; font-weight: bold; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'>RealtyMonster</div>
    </div>
  </header>
  
  <div class='container'>
    <h1>Apartment Not Found</h1>
    <p>Sorry, the apartment you are looking for does not exist or may have been removed.</p>
    <a href='/' class='btn'>Back to All Apartments</a>
  </div>
</body>
</html>"
    end
  elsif path == "/api/apartments"
    # API endpoint for apartments - returns JSON data
    filtered_apartments = filter_apartments(query_params)
    
    response_content = JSON.generate(filtered_apartments)
    
    headers = [
      "HTTP/1.1 200 OK",
      "Content-Type: application/json; charset=utf-8",
      "Content-Length: #{response_content.bytesize}",
      "Connection: close",
    ]
    
    client.puts headers.join("\r\n")
    client.puts "\r\n"
    client.puts response_content
    client.close
    next
  else
    # Page not found
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>Page Not Found - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #333; text-align: center; }
    h1 { color: #e74c3c; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .btn { display: inline-block; background: #3498db; color: white; padding: 10px 15px; 
           text-decoration: none; border-radius: 4px; margin-top: 20px; }
    .header { background-color: #34495e; color: white; padding: 20px 0; margin-bottom: 30px; }
    .logo { font-size: 24px; font-weight: bold; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'>RealtyMonster</div>
    </div>
  </header>
  
  <div class='container'>
    <h1>404 - Page Not Found</h1>
    <p>The page you are looking for does not exist.</p>
    <a href='/' class='btn'>Back to Home</a>
  </div>
</body>
</html>"
  end
  
  # Send response
  headers = [
    "HTTP/1.1 200 OK",
    "Content-Type: text/html; charset=utf-8",
    "Content-Length: #{response_content.bytesize}",
    "Connection: close",
  ]
  
  client.puts headers.join("\r\n")
  client.puts "\r\n"
  client.puts response_content
  
  client.close
end