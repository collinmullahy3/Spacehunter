require 'socket'
require 'uri'
require 'json'

# Site configuration
SITE_NAME = "SpaceHunter"
LOGO_HTML = "<img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter"

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
    image_url: "/images/apt1.jpg", # Would point to an actual image if we had one
    property_type: "Condo",
    lease_term: "12 Months",
    utilities_included: ["Water", "Heat"],
    amenities: ["Elevator", "Doorman", "Fitness Center", "Rooftop Deck"],
    status: "Available",
    last_updated: "2023-09-01",
    broker_fee: true,
    security_deposit: 3500
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
    image_url: "/images/apt2.jpg",
    property_type: "Apartment",
    lease_term: "12-24 Months",
    utilities_included: ["Water"],
    amenities: ["Laundry in Building", "Rooftop Access"],
    status: "Available",
    last_updated: "2023-09-05",
    broker_fee: false,
    security_deposit: 1800
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
    image_url: "/images/apt3.jpg",
    property_type: "Townhouse",
    lease_term: "12 Months",
    utilities_included: ["None"],
    amenities: ["Backyard", "Basement Storage"],
    status: "Available",
    last_updated: "2023-08-20",
    broker_fee: true,
    security_deposit: 5600
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
    image_url: "/images/apt4.jpg",
    property_type: "Apartment",
    lease_term: "12 Months",
    utilities_included: ["Water", "Gas"],
    amenities: ["Bicycle Storage", "Renovated"],
    status: "Available",
    last_updated: "2023-07-10",
    broker_fee: false,
    security_deposit: 2400
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
    image_url: "/images/apt5.jpg",
    property_type: "Co-op",
    lease_term: "24 Months",
    utilities_included: ["Heat", "Water"],
    amenities: ["Elevator", "Doorman", "Live-in Super", "Laundry Room"],
    status: "Available",
    last_updated: "2023-08-15",
    broker_fee: true,
    security_deposit: 8400
  }
]

# Simple user authentication
USERS = [
  {
    id: 1,
    username: "admin",
    password: "admin123", # In a real app, this would be hashed
    role: "admin"
  },
  {
    id: 2,
    username: "landlord",
    password: "property456",
    role: "landlord"
  },
  {
    id: 3,
    username: "user",
    password: "renter789",
    role: "renter"
  }
]

# Global variable to track current user session (in a real app, use proper session management)
$current_user = nil

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
  
  # Filter by min price
  if params['min_price'] && !params['min_price'].empty?
    min_price = params['min_price'].to_i
    filtered = filtered.select { |apt| apt[:price] >= min_price }
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
  
  # Filter by property type
  if params['property_type'] && !params['property_type'].empty?
    filtered = filtered.select { |apt| apt[:property_type] == params['property_type'] }
  end
  
  # Filter by lease term
  if params['lease_term'] && !params['lease_term'].empty?
    filtered = filtered.select { |apt| apt[:lease_term].include?(params['lease_term']) }
  end
  
  # Filter by amenities
  if params['amenities'] && !params['amenities'].empty?
    amenity = params['amenities'].downcase
    filtered = filtered.select { |apt| apt[:amenities].any? { |a| a.downcase.include?(amenity) } }
  end
  
  # Filter by square footage
  if params['min_square_feet'] && !params['min_square_feet'].empty?
    min_sq_ft = params['min_square_feet'].to_i
    filtered = filtered.select { |apt| apt[:square_feet] >= min_sq_ft }
  end
  
  # Filter by date available
  if params['available_from'] && !params['available_from'].empty?
    # In a real app, we would properly compare dates
    # For simplicity, we'll just do a string comparison for now
    filtered = filtered.select { |apt| apt[:available_from] >= params['available_from'] }
  end
  
  # Filter by broker fee
  if params['no_broker_fee'] == 'true'
    filtered = filtered.select { |apt| !apt[:broker_fee] }
  end
  
  filtered
end

# Helper method for authentication
def authenticate(username, password)
  user = USERS.find { |u| u[:username] == username && u[:password] == password }
  $current_user = user
  !user.nil?
end

# Helper method to check if user is admin
def admin?
  $current_user && $current_user[:role] == "admin"
end

# Helper method to check if user is landlord
def landlord?
  $current_user && ($current_user[:role] == "landlord" || $current_user[:role] == "admin")
end

# Helper method for adding a new apartment
def add_apartment(params)
  new_id = APARTMENTS.map { |apt| apt[:id] }.max + 1
  
  new_apartment = {
    id: new_id,
    title: params['title'] || "New Listing",
    location: params['location'] || "Address not provided",
    price: params['price'] ? params['price'].to_i : 0,
    bedrooms: params['bedrooms'] ? params['bedrooms'].to_i : 0,
    bathrooms: params['bathrooms'] ? params['bathrooms'].to_f : 0,
    square_feet: params['square_feet'] ? params['square_feet'].to_i : 0,
    description: params['description'] || "No description provided",
    features: params['features'] ? params['features'].split(',').map(&:strip) : [],
    available_from: params['available_from'] || "Immediately",
    neighborhood: params['neighborhood'] || "Not specified",
    pet_friendly: params['pet_friendly'] == "true",
    parking: params['parking'] || "None",
    image_url: params['image_url'] || "/images/default.jpg",
    property_type: params['property_type'] || "Apartment",
    lease_term: params['lease_term'] || "12 Months",
    utilities_included: params['utilities_included'] ? params['utilities_included'].split(',').map(&:strip) : [],
    amenities: params['amenities'] ? params['amenities'].split(',').map(&:strip) : [],
    status: "Available",
    last_updated: Time.now.strftime("%Y-%m-%d"),
    broker_fee: params['broker_fee'] == "true",
    security_deposit: params['security_deposit'] ? params['security_deposit'].to_i : 0
  }
  
  APARTMENTS << new_apartment
  new_apartment
end

# Helper method for updating an apartment
def update_apartment(id, params)
  apartment = APARTMENTS.find { |apt| apt[:id] == id.to_i }
  return nil unless apartment
  
  # Update fields that are provided
  apartment[:title] = params['title'] if params['title']
  apartment[:location] = params['location'] if params['location']
  apartment[:price] = params['price'].to_i if params['price']
  apartment[:bedrooms] = params['bedrooms'].to_i if params['bedrooms']
  apartment[:bathrooms] = params['bathrooms'].to_f if params['bathrooms']
  apartment[:square_feet] = params['square_feet'].to_i if params['square_feet']
  apartment[:description] = params['description'] if params['description']
  apartment[:features] = params['features'].split(',').map(&:strip) if params['features']
  apartment[:available_from] = params['available_from'] if params['available_from']
  apartment[:neighborhood] = params['neighborhood'] if params['neighborhood']
  apartment[:pet_friendly] = params['pet_friendly'] == "true" if params.key?('pet_friendly')
  apartment[:parking] = params['parking'] if params['parking']
  apartment[:image_url] = params['image_url'] if params['image_url']
  apartment[:property_type] = params['property_type'] if params['property_type']
  apartment[:lease_term] = params['lease_term'] if params['lease_term']
  apartment[:utilities_included] = params['utilities_included'].split(',').map(&:strip) if params['utilities_included']
  apartment[:amenities] = params['amenities'].split(',').map(&:strip) if params['amenities']
  apartment[:status] = params['status'] if params['status']
  apartment[:broker_fee] = params['broker_fee'] == "true" if params.key?('broker_fee')
  apartment[:security_deposit] = params['security_deposit'].to_i if params['security_deposit']
  
  # Update the last_updated timestamp
  apartment[:last_updated] = Time.now.strftime("%Y-%m-%d")
  
  apartment
end

# Helper method for deleting an apartment
def delete_apartment(id)
  index = APARTMENTS.find_index { |apt| apt[:id] == id.to_i }
  return false unless index
  
  APARTMENTS.delete_at(index)
  true
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
  if path == "/login"
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>Login - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; background-color: #f9f9f9; }
    h1, h2, h3 { color: #515151; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 28px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
    .login-container { max-width: 400px; margin: 50px auto; background-color: white; border-radius: 8px; padding: 35px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }
    .form-group { margin-bottom: 20px; }
    .form-group label { display: block; margin-bottom: 5px; font-weight: bold; color: #515151; }
    .form-group input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; color: #515151; }
    .form-group input:focus { border-color: #f7b419; outline: none; box-shadow: 0 0 0 2px rgba(247, 180, 25, 0.2); }
    .btn { display: inline-block; background: #f7b419; color: #515151; padding: 12px 20px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px;
           font-weight: bold; width: 100%; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
    .error-message { color: #e74c3c; margin-bottom: 15px; }
    .footer { background-color: #515151; color: white; padding: 40px 0; margin-top: 50px; }
    .back-link { display: block; margin-top: 20px; text-align: center; color: #f7b419; text-decoration: none; font-weight: bold; }
    .back-link:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
    </div>
  </header>
  
  <div class='container'>
    <div class='login-container'>
      <h2>Login to RealtyMonster</h2>
      
      <form action='/authenticate' method='post'>
        <div class='form-group'>
          <label for='username'>Username</label>
          <input type='text' id='username' name='username' required>
        </div>
        <div class='form-group'>
          <label for='password'>Password</label>
          <input type='password' id='password' name='password' required>
        </div>
        
        <button type='submit' class='btn'>Login</button>
      </form>
      
      <a href='/' class='back-link'>Back to Home</a>
    </div>
  </div>
  
  <footer class='footer'>
    <div class='container'>
      <p>&copy; 2025 RealtyMonster. All rights reserved.</p>
    </div>
  </footer>
</body>
</html>"
  elsif ["/admin", "/admin/apartments", "/admin/dashboard"].include?(path)
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>Admin Portal - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; }
    h1, h2, h3 { color: #515151; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 28px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
    .admin-panel { display: flex; gap: 30px; margin-bottom: 40px; }
    .admin-sidebar { flex: 1; background-color: #f9f9f9; padding: 25px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }
    .admin-content { flex: 3; }
    .sidebar-menu { list-style-type: none; padding: 0; margin: 0; }
    .sidebar-menu li { margin-bottom: 12px; }
    .sidebar-menu a { display: block; padding: 12px 15px; text-decoration: none; color: #515151; border-radius: 4px; transition: all 0.3s ease; font-weight: bold; }
    .sidebar-menu a:hover { background-color: #f7b419; color: #515151; transform: translateX(5px); }
    .sidebar-menu a.active { background-color: #f7b419; color: #515151; }
    .admin-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; }
    .btn { display: inline-block; background: #f7b419; color: #515151; padding: 12px 20px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; 
           font-weight: bold; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
    .btn-green { background-color: #f7b419; }
    .btn-green:hover { background-color: #ffc53d; }
    .btn-red { background-color: #515151; color: white; }
    .btn-red:hover { background-color: #666666; }
    .table { width: 100%; border-collapse: collapse; margin-bottom: 30px; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; }
    .table th, .table td { padding: 15px; text-align: left; border-bottom: 1px solid #e0e0e0; }
    .table th { background-color: #f5f5f5; font-weight: bold; color: #515151; }
    .table tbody tr:hover { background-color: #f9f9f9; }
    .badge { display: inline-block; padding: 6px 12px; border-radius: 50px; font-size: 12px; font-weight: bold; }
    .badge-success { background-color: rgba(247, 180, 25, 0.2); color: #f7b419; }
    .badge-warning { background-color: rgba(243, 156, 18, 0.2); color: #f39c12; }
    .badge-danger { background-color: rgba(231, 76, 60, 0.2); color: #e74c3c; }
    .action-buttons { display: flex; gap: 8px; }
    .login-prompt { text-align: center; margin: 100px 0; }
    .footer { background-color: #515151; color: white; padding: 40px 0; margin-top: 50px; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
    </div>
  </header>
  
  <div class='container'>
    <h1>Admin Portal</h1>
    
    <div class='admin-panel'>
      <div class='admin-sidebar'>
        <ul class='sidebar-menu'>
          <li><a href='/admin' class='active'>Dashboard</a></li>
          <li><a href='/admin/apartments'>Apartments</a></li>
          <li><a href='/admin/users'>Users</a></li>
          <li><a href='/admin/inquiries'>Inquiries</a></li>
          <li><a href='/admin/settings'>Settings</a></li>
          <li><a href='/logout'>Logout</a></li>
        </ul>
      </div>
      
      <div class='admin-content'>
        <div class='admin-header'>
          <h2>Apartment Listings</h2>
          <a href='/admin/apartments/new' class='btn btn-green'>Add New Listing</a>
        </div>
        
        <table class='table'>
          <thead>
            <tr>
              <th>ID</th>
              <th>Title</th>
              <th>Location</th>
              <th>Price</th>
              <th>Bedrooms</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            #{APARTMENTS.map { |apt| "
            <tr>
              <td>#{apt[:id]}</td>
              <td>#{apt[:title]}</td>
              <td>#{apt[:neighborhood]}</td>
              <td>$#{apt[:price]}</td>
              <td>#{apt[:bedrooms] == 0 ? 'Studio' : apt[:bedrooms]}</td>
              <td><span class='badge badge-success'>#{apt[:status]}</span></td>
              <td class='action-buttons'>
                <a href='/admin/apartments/#{apt[:id]}/edit' class='btn' style='padding: 5px 10px; font-size: 12px;'>Edit</a>
                <a href='/admin/apartments/#{apt[:id]}/delete' class='btn btn-red' style='padding: 5px 10px; font-size: 12px;'>Delete</a>
              </td>
            </tr>" }.join("\n            ")}
          </tbody>
        </table>
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
  elsif path == "/admin/users"
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>User Management - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; }
    h1, h2, h3 { color: #515151; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 28px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
    .admin-panel { display: flex; gap: 30px; margin-bottom: 40px; }
    .admin-sidebar { flex: 1; background-color: #f9f9f9; padding: 25px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }
    .admin-content { flex: 3; }
    .sidebar-menu { list-style-type: none; padding: 0; margin: 0; }
    .sidebar-menu li { margin-bottom: 12px; }
    .sidebar-menu a { display: block; padding: 12px 15px; text-decoration: none; color: #515151; border-radius: 4px; transition: all 0.3s ease; font-weight: bold; }
    .sidebar-menu a:hover { background-color: #f7b419; color: #515151; transform: translateX(5px); }
    .sidebar-menu a.active { background-color: #f7b419; color: #515151; }
    .admin-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; }
    .btn { display: inline-block; background: #f7b419; color: #515151; padding: 12px 20px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; 
           font-weight: bold; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
    .table { width: 100%; border-collapse: collapse; margin-bottom: 30px; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; }
    .table th, .table td { padding: 15px; text-align: left; border-bottom: 1px solid #e0e0e0; }
    .table th { background-color: #f5f5f5; font-weight: bold; color: #515151; }
    .table tbody tr:hover { background-color: #f9f9f9; }
    .badge { display: inline-block; padding: 6px 12px; border-radius: 50px; font-size: 12px; font-weight: bold; }
    .badge-admin { background-color: rgba(231, 76, 60, 0.2); color: #e74c3c; }
    .badge-landlord { background-color: rgba(52, 152, 219, 0.2); color: #3498db; }
    .badge-renter { background-color: rgba(46, 204, 113, 0.2); color: #2ecc71; }
    .action-buttons { display: flex; gap: 8px; }
    .footer { background-color: #515151; color: white; padding: 40px 0; margin-top: 50px; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
    </div>
  </header>
  
  <div class='container'>
    <h1>User Management</h1>
    
    <div class='admin-panel'>
      <div class='admin-sidebar'>
        <ul class='sidebar-menu'>
          <li><a href='/admin'>Dashboard</a></li>
          <li><a href='/admin/apartments'>Apartments</a></li>
          <li><a href='/admin/users' class='active'>Users</a></li>
          <li><a href='/admin/inquiries'>Inquiries</a></li>
          <li><a href='/admin/settings'>Settings</a></li>
          <li><a href='/logout'>Logout</a></li>
        </ul>
      </div>
      
      <div class='admin-content'>
        <div class='admin-header'>
          <h2>Registered Users</h2>
          <a href='/admin/users/new' class='btn'>Add New User</a>
        </div>
        
        <table class='table'>
          <thead>
            <tr>
              <th>ID</th>
              <th>Username</th>
              <th>Role</th>
              <th>Last Login</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            #{USERS.map { |user| "
            <tr>
              <td>#{user[:id]}</td>
              <td>#{user[:username]}</td>
              <td><span class='badge badge-#{user[:role]}'>#{user[:role].capitalize}</span></td>
              <td>May 6, 2025</td>
              <td>Active</td>
              <td class='action-buttons'>
                <a href='/admin/users/#{user[:id]}/edit' class='btn' style='padding: 5px 10px; font-size: 12px;'>Edit</a>
                <a href='/admin/users/#{user[:id]}/delete' class='btn btn-red' style='padding: 5px 10px; font-size: 12px;'>Delete</a>
              </td>
            </tr>" }.join("\n            ")}
          </tbody>
        </table>
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
  elsif path == "/admin/inquiries"
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>Inquiries - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; }
    h1, h2, h3 { color: #515151; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 28px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
    .admin-panel { display: flex; gap: 30px; margin-bottom: 40px; }
    .admin-sidebar { flex: 1; background-color: #f9f9f9; padding: 25px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }
    .admin-content { flex: 3; }
    .sidebar-menu { list-style-type: none; padding: 0; margin: 0; }
    .sidebar-menu li { margin-bottom: 12px; }
    .sidebar-menu a { display: block; padding: 12px 15px; text-decoration: none; color: #515151; border-radius: 4px; transition: all 0.3s ease; font-weight: bold; }
    .sidebar-menu a:hover { background-color: #f7b419; color: #515151; transform: translateX(5px); }
    .sidebar-menu a.active { background-color: #f7b419; color: #515151; }
    .admin-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; }
    .btn { display: inline-block; background: #f7b419; color: #515151; padding: 12px 20px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; 
           font-weight: bold; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
    .table { width: 100%; border-collapse: collapse; margin-bottom: 30px; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; }
    .table th, .table td { padding: 15px; text-align: left; border-bottom: 1px solid #e0e0e0; }
    .table th { background-color: #f5f5f5; font-weight: bold; color: #515151; }
    .table tbody tr:hover { background-color: #f9f9f9; }
    .badge { display: inline-block; padding: 6px 12px; border-radius: 50px; font-size: 12px; font-weight: bold; }
    .badge-new { background-color: rgba(247, 180, 25, 0.2); color: #f7b419; }
    .badge-replied { background-color: rgba(46, 204, 113, 0.2); color: #2ecc71; }
    .badge-urgent { background-color: rgba(231, 76, 60, 0.2); color: #e74c3c; }
    .action-buttons { display: flex; gap: 8px; }
    .footer { background-color: #515151; color: white; padding: 40px 0; margin-top: 50px; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
    </div>
  </header>
  
  <div class='container'>
    <h1>Customer Inquiries</h1>
    
    <div class='admin-panel'>
      <div class='admin-sidebar'>
        <ul class='sidebar-menu'>
          <li><a href='/admin'>Dashboard</a></li>
          <li><a href='/admin/apartments'>Apartments</a></li>
          <li><a href='/admin/users'>Users</a></li>
          <li><a href='/admin/inquiries' class='active'>Inquiries</a></li>
          <li><a href='/admin/settings'>Settings</a></li>
          <li><a href='/logout'>Logout</a></li>
        </ul>
      </div>
      
      <div class='admin-content'>
        <div class='admin-header'>
          <h2>Recent Inquiries</h2>
          <div>
            <a href='/admin/inquiries?filter=new' class='btn' style='background-color: #f7b419; margin-right: 10px;'>New</a>
            <a href='/admin/inquiries?filter=all' class='btn' style='background-color: #515151; color: white;'>All</a>
          </div>
        </div>
        
        <table class='table'>
          <thead>
            <tr>
              <th>ID</th>
              <th>Property</th>
              <th>Customer</th>
              <th>Date</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>1</td>
              <td>Luxurious Downtown Penthouse</td>
              <td>John Smith <br><small>john.smith@example.com</small></td>
              <td>May 6, 2025</td>
              <td><span class='badge badge-new'>New</span></td>
              <td class='action-buttons'>
                <a href='/admin/inquiries/1/view' class='btn' style='padding: 5px 10px; font-size: 12px;'>View</a>
                <a href='/admin/inquiries/1/reply' class='btn' style='padding: 5px 10px; font-size: 12px; background-color: #2ecc71;'>Reply</a>
              </td>
            </tr>
            <tr>
              <td>2</td>
              <td>Cozy Midtown Studio</td>
              <td>Emma Johnson <br><small>emma.j@example.com</small></td>
              <td>May 5, 2025</td>
              <td><span class='badge badge-replied'>Replied</span></td>
              <td class='action-buttons'>
                <a href='/admin/inquiries/2/view' class='btn' style='padding: 5px 10px; font-size: 12px;'>View</a>
              </td>
            </tr>
            <tr>
              <td>3</td>
              <td>Spacious Brooklyn Brownstone</td>
              <td>Michael Brown <br><small>mbrown@example.com</small></td>
              <td>May 4, 2025</td>
              <td><span class='badge badge-urgent'>Urgent</span></td>
              <td class='action-buttons'>
                <a href='/admin/inquiries/3/view' class='btn' style='padding: 5px 10px; font-size: 12px;'>View</a>
                <a href='/admin/inquiries/3/reply' class='btn' style='padding: 5px 10px; font-size: 12px; background-color: #2ecc71;'>Reply</a>
              </td>
            </tr>
          </tbody>
        </table>
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
  elsif path == "/admin/settings"
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>Settings - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; }
    h1, h2, h3 { color: #515151; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 28px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
    .admin-panel { display: flex; gap: 30px; margin-bottom: 40px; }
    .admin-sidebar { flex: 1; background-color: #f9f9f9; padding: 25px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }
    .admin-content { flex: 3; }
    .sidebar-menu { list-style-type: none; padding: 0; margin: 0; }
    .sidebar-menu li { margin-bottom: 12px; }
    .sidebar-menu a { display: block; padding: 12px 15px; text-decoration: none; color: #515151; border-radius: 4px; transition: all 0.3s ease; font-weight: bold; }
    .sidebar-menu a:hover { background-color: #f7b419; color: #515151; transform: translateX(5px); }
    .sidebar-menu a.active { background-color: #f7b419; color: #515151; }
    .admin-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; }
    .btn { display: inline-block; background: #f7b419; color: #515151; padding: 12px 20px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; 
           font-weight: bold; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
    .settings-section { background-color: white; padding: 25px; border-radius: 8px; margin-bottom: 25px; border: 1px solid #e0e0e0; }
    .form-group { margin-bottom: 20px; }
    .form-group label { display: block; margin-bottom: 8px; font-weight: bold; }
    .form-group input, .form-group select, .form-group textarea { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; }
    .form-group input:focus, .form-group select:focus, .form-group textarea:focus { border-color: #f7b419; outline: none; box-shadow: 0 0 0 2px rgba(247, 180, 25, 0.2); }
    .footer { background-color: #515151; color: white; padding: 40px 0; margin-top: 50px; }
    .checkbox-group { display: flex; align-items: center; }
    .checkbox-group input { width: auto; margin-right: 10px; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
    </div>
  </header>
  
  <div class='container'>
    <h1>System Settings</h1>
    
    <div class='admin-panel'>
      <div class='admin-sidebar'>
        <ul class='sidebar-menu'>
          <li><a href='/admin'>Dashboard</a></li>
          <li><a href='/admin/apartments'>Apartments</a></li>
          <li><a href='/admin/users'>Users</a></li>
          <li><a href='/admin/inquiries'>Inquiries</a></li>
          <li><a href='/admin/settings' class='active'>Settings</a></li>
          <li><a href='/logout'>Logout</a></li>
        </ul>
      </div>
      
      <div class='admin-content'>
        <form action='/admin/settings/update' method='post'>
          <div class='settings-section'>
            <h2>General Settings</h2>
            
            <div class='form-group'>
              <label for='site_title'>Site Title</label>
              <input type='text' id='site_title' name='site_title' value='RealtyMonster'>
            </div>
            
            <div class='form-group'>
              <label for='site_description'>Site Description</label>
              <textarea id='site_description' name='site_description' rows='3'>Find your perfect apartment with RealtyMonster, the premier apartment listing platform.</textarea>
            </div>
            
            <div class='form-group'>
              <label for='contact_email'>Contact Email</label>
              <input type='email' id='contact_email' name='contact_email' value='contact@realtymonster.com'>
            </div>
          </div>
          
          <div class='settings-section'>
            <h2>Notification Settings</h2>
            
            <div class='form-group checkbox-group'>
              <input type='checkbox' id='email_new_listing' name='email_new_listing' checked>
              <label for='email_new_listing'>Email notification for new listings</label>
            </div>
            
            <div class='form-group checkbox-group'>
              <input type='checkbox' id='email_new_inquiry' name='email_new_inquiry' checked>
              <label for='email_new_inquiry'>Email notification for new inquiries</label>
            </div>
            
            <div class='form-group checkbox-group'>
              <input type='checkbox' id='email_new_user' name='email_new_user' checked>
              <label for='email_new_user'>Email notification for new user registrations</label>
            </div>
          </div>
          
          <button type='submit' class='btn'>Save Settings</button>
        </form>
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
  elsif path == "/advanced-search"
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>Advanced Search - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; }
    h1, h2, h3 { color: #515151; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 28px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
    .back-link { display: inline-block; margin-bottom: 20px; color: #f7b419; text-decoration: none; font-weight: bold; }
    .back-link:hover { text-decoration: underline; }
    .search-container { background-color: #f9f9f9; padding: 30px; border-radius: 8px; margin-bottom: 30px; border: 1px solid #e0e0e0; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
    .form-group { margin-bottom: 15px; }
    .form-group label { display: block; margin-bottom: 5px; font-weight: bold; color: #515151; }
    .form-group input, .form-group select, .form-group textarea { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; color: #515151; }
    .form-group input:focus, .form-group select:focus, .form-group textarea:focus { border-color: #f7b419; outline: none; box-shadow: 0 0 0 2px rgba(247, 180, 25, 0.2); }
    .form-row { display: flex; gap: 15px; margin-bottom: 15px; }
    .form-row .form-group { flex: 1; }
    .checkbox-group { display: flex; align-items: center; }
    .checkbox-group input { width: auto; margin-right: 10px; }
    .checkbox-group input:checked { accent-color: #f7b419; }
    .btn { display: inline-block; background: #f7b419; color: #515151; padding: 12px 20px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; 
           font-weight: bold; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
    .btn-search { background: #f7b419; padding: 12px 20px; }
    .btn-search:hover { background: #ffc53d; }
    .btn-reset { background: #515151; color: white; }
    .btn-reset:hover { background: #666666; }
    .search-title { margin-bottom: 30px; }
    .search-title h1 { margin-bottom: 10px; color: #515151; }
    .search-title p { color: #757575; font-size: 18px; }
    .search-section { margin-bottom: 30px; }
    .search-section h3 { border-bottom: 1px solid #ddd; padding-bottom: 10px; margin-bottom: 20px; color: #515151; }
    .feature-checkboxes { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 10px; }
    .range-inputs { display: flex; gap: 10px; align-items: center; }
    .range-inputs span { font-weight: bold; color: #515151; }
    .double-range { margin-bottom: 30px; }
    .footer { background-color: #515151; color: white; padding: 40px 0; margin-top: 50px; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
    </div>
  </header>
  
  <div class='container'>
    <a href='/' class='back-link'>&larr; Back to Basic Search</a>
    
    <div class='search-title'>
      <h1>Advanced Apartment Search</h1>
      <p>Find your perfect home with our powerful search tools</p>
    </div>
    
    <div class='search-container'>
      <form action='/' method='get'>
        <div class='search-section'>
          <h3>Location & Property Type</h3>
          <div class='form-row'>
            <div class='form-group'>
              <label for='neighborhood'>Neighborhood</label>
              <input type='text' id='neighborhood' name='neighborhood' placeholder='E.g. Downtown, Midtown, etc.' value='#{query_params['neighborhood'] || ''}'>
            </div>
            <div class='form-group'>
              <label for='property_type'>Property Type</label>
              <select id='property_type' name='property_type'>
                <option value='' #{query_params['property_type'].nil? || query_params['property_type'].empty? ? 'selected' : ''}>Any</option>
                <option value='Apartment' #{query_params['property_type'] == 'Apartment' ? 'selected' : ''}>Apartment</option>
                <option value='Condo' #{query_params['property_type'] == 'Condo' ? 'selected' : ''}>Condo</option>
                <option value='Townhouse' #{query_params['property_type'] == 'Townhouse' ? 'selected' : ''}>Townhouse</option>
                <option value='Co-op' #{query_params['property_type'] == 'Co-op' ? 'selected' : ''}>Co-op</option>
              </select>
            </div>
            <div class='form-group'>
              <label for='address_keyword'>Address Keyword</label>
              <input type='text' id='address_keyword' name='address_keyword' placeholder='E.g. Main Street, Avenue, etc.' value='#{query_params['address_keyword'] || ''}'>
            </div>
          </div>
        </div>
        
        <div class='search-section'>
          <h3>Size & Layout</h3>
          <div class='form-row'>
            <div class='form-group'>
              <label for='min_bedrooms'>Bedrooms</label>
              <select id='min_bedrooms' name='min_bedrooms'>
                <option value='' #{query_params['min_bedrooms'].nil? || query_params['min_bedrooms'].empty? ? 'selected' : ''}>Any</option>
                <option value='0' #{query_params['min_bedrooms'] == '0' ? 'selected' : ''}>Studio</option>
                <option value='1' #{query_params['min_bedrooms'] == '1' ? 'selected' : ''}>1+ Bedrooms</option>
                <option value='2' #{query_params['min_bedrooms'] == '2' ? 'selected' : ''}>2+ Bedrooms</option>
                <option value='3' #{query_params['min_bedrooms'] == '3' ? 'selected' : ''}>3+ Bedrooms</option>
                <option value='4' #{query_params['min_bedrooms'] == '4' ? 'selected' : ''}>4+ Bedrooms</option>
              </select>
            </div>
            <div class='form-group'>
              <label for='min_bathrooms'>Minimum Bathrooms</label>
              <select id='min_bathrooms' name='min_bathrooms'>
                <option value='' #{query_params['min_bathrooms'].nil? || query_params['min_bathrooms'].empty? ? 'selected' : ''}>Any</option>
                <option value='1' #{query_params['min_bathrooms'] == '1' ? 'selected' : ''}>1+ Bathrooms</option>
                <option value='1.5' #{query_params['min_bathrooms'] == '1.5' ? 'selected' : ''}>1.5+ Bathrooms</option>
                <option value='2' #{query_params['min_bathrooms'] == '2' ? 'selected' : ''}>2+ Bathrooms</option>
                <option value='2.5' #{query_params['min_bathrooms'] == '2.5' ? 'selected' : ''}>2.5+ Bathrooms</option>
                <option value='3' #{query_params['min_bathrooms'] == '3' ? 'selected' : ''}>3+ Bathrooms</option>
              </select>
            </div>
          </div>
          
          <div class='form-row'>
            <div class='form-group'>
              <label for='min_square_feet'>Square Feet Range</label>
              <div class='range-inputs'>
                <input type='number' id='min_square_feet' name='min_square_feet' placeholder='Min' value='#{query_params['min_square_feet'] || ''}'>
                <span>to</span>
                <input type='number' id='max_square_feet' name='max_square_feet' placeholder='Max' value='#{query_params['max_square_feet'] || ''}'>
              </div>
            </div>
          </div>
        </div>
        
        <div class='search-section'>
          <h3>Price & Terms</h3>
          <div class='form-row'>
            <div class='form-group'>
              <label for='price_range'>Monthly Rent Range ($)</label>
              <div class='range-inputs'>
                <input type='number' id='min_price' name='min_price' placeholder='Min' value='#{query_params['min_price'] || ''}'>
                <span>to</span>
                <input type='number' id='max_price' name='max_price' placeholder='Max' value='#{query_params['max_price'] || ''}'>
              </div>
            </div>
            <div class='form-group'>
              <label for='lease_term'>Lease Term</label>
              <select id='lease_term' name='lease_term'>
                <option value='' #{query_params['lease_term'].nil? || query_params['lease_term'].empty? ? 'selected' : ''}>Any</option>
                <option value='12 Months' #{query_params['lease_term'] == '12 Months' ? 'selected' : ''}>12 Months</option>
                <option value='24 Months' #{query_params['lease_term'] == '24 Months' ? 'selected' : ''}>24 Months</option>
                <option value='Month-to-Month' #{query_params['lease_term'] == 'Month-to-Month' ? 'selected' : ''}>Month-to-Month</option>
              </select>
            </div>
          </div>
          
          <div class='form-row'>
            <div class='form-group'>
              <label for='security_deposit'>Maximum Security Deposit ($)</label>
              <input type='number' id='max_security_deposit' name='max_security_deposit' value='#{query_params['max_security_deposit'] || ''}'>
            </div>
            <div class='form-group'>
              <label for='available_from'>Available From</label>
              <input type='date' id='available_from' name='available_from' value='#{query_params['available_from'] || ''}'>
            </div>
          </div>
          
          <div class='form-row'>
            <div class='form-group checkbox-group'>
              <input type='checkbox' id='no_broker_fee' name='no_broker_fee' value='true' #{query_params['no_broker_fee'] == 'true' ? 'checked' : ''}>
              <label for='no_broker_fee'>No Broker Fee</label>
            </div>
          </div>
        </div>
        
        <div class='search-section'>
          <h3>Amenities & Features</h3>
          <div class='form-row'>
            <div class='form-group'>
              <label for='amenities'>Amenities (comma separated)</label>
              <input type='text' id='amenities' name='amenities' placeholder='E.g. Elevator, Doorman, Gym, etc.' value='#{query_params['amenities'] || ''}'>
            </div>
          </div>
          
          <div class='form-row'>
            <div class='form-group checkbox-group'>
              <input type='checkbox' id='pet_friendly' name='pet_friendly' value='true' #{query_params['pet_friendly'] == 'true' ? 'checked' : ''}>
              <label for='pet_friendly'>Pet Friendly</label>
            </div>
            <div class='form-group checkbox-group'>
              <input type='checkbox' id='has_parking' name='has_parking' value='true' #{query_params['has_parking'] == 'true' ? 'checked' : ''}>
              <label for='has_parking'>Parking Available</label>
            </div>
            <div class='form-group checkbox-group'>
              <input type='checkbox' id='has_outdoor_space' name='has_outdoor_space' value='true' #{query_params['has_outdoor_space'] == 'true' ? 'checked' : ''}>
              <label for='has_outdoor_space'>Outdoor Space</label>
            </div>
          </div>
          
          <div class='form-row'>
            <div class='form-group'>
              <label for='utilities_included'>Utilities Included</label>
              <select id='utilities_included' name='utilities_included'>
                <option value='' #{query_params['utilities_included'].nil? || query_params['utilities_included'].empty? ? 'selected' : ''}>Any</option>
                <option value='Water' #{query_params['utilities_included'] == 'Water' ? 'selected' : ''}>Water</option>
                <option value='Heat' #{query_params['utilities_included'] == 'Heat' ? 'selected' : ''}>Heat</option>
                <option value='Gas' #{query_params['utilities_included'] == 'Gas' ? 'selected' : ''}>Gas</option>
                <option value='Electric' #{query_params['utilities_included'] == 'Electric' ? 'selected' : ''}>Electric</option>
              </select>
            </div>
          </div>
        </div>
        
        <div class='form-row'>
          <button type='submit' class='btn btn-search'>Search Apartments</button>
          <a href='/' class='btn btn-reset'>Reset Filters</a>
        </div>
      </form>
    </div>
  </div>
  
  <footer class='footer'>
    <div class='container'>
      <p>&copy; 2025 RealtyMonster. All rights reserved.</p>
    </div>
  </footer>
</body>
</html>"
  elsif path == "/admin/apartments/new"
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>Add New Apartment - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #333; }
    h1, h2, h3 { color: #2c3e50; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #34495e; color: white; padding: 20px 0; margin-bottom: 30px; }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 24px; font-weight: bold; }
    .admin-panel { display: flex; gap: 30px; margin-bottom: 40px; }
    .admin-sidebar { flex: 1; background-color: #f8f9fa; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .admin-content { flex: 3; }
    .sidebar-menu { list-style-type: none; padding: 0; margin: 0; }
    .sidebar-menu li { margin-bottom: 10px; }
    .sidebar-menu a { display: block; padding: 10px; text-decoration: none; color: #333; border-radius: 4px; transition: background-color 0.3s; }
    .sidebar-menu a:hover, .sidebar-menu a.active { background-color: #e0e0e0; }
    .form-card { background-color: #f8f9fa; border-radius: 8px; padding: 30px; margin-bottom: 30px; }
    .form-group { margin-bottom: 20px; }
    .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
    .form-group input, .form-group textarea, .form-group select { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
    .form-group textarea { min-height: 150px; }
    .form-row { display: flex; gap: 20px; }
    .form-row .form-group { flex: 1; }
    .checkbox-group { display: flex; align-items: center; }
    .checkbox-group input { width: auto; margin-right: 10px; }
    .btn { display: inline-block; background: #3498db; color: white; padding: 10px 15px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; }
    .btn:hover { background: #2980b9; }
    .btn-green { background-color: #27ae60; }
    .btn-green:hover { background-color: #219653; }
    .footer { background-color: #34495e; color: white; padding: 30px 0; margin-top: 50px; }
    .back-link { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; }
    .back-link:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
    </div>
  </header>
  
  <div class='container'>
    <a href='/admin' class='back-link'>&larr; Back to Admin Dashboard</a>
    
    <h1>Add New Apartment Listing</h1>
    
    <div class='admin-panel'>
      <div class='admin-sidebar'>
        <ul class='sidebar-menu'>
          <li><a href='/admin'>Dashboard</a></li>
          <li><a href='/admin/apartments' class='active'>Apartments</a></li>
          <li><a href='/admin/users'>Users</a></li>
          <li><a href='/admin/inquiries'>Inquiries</a></li>
          <li><a href='/admin/settings'>Settings</a></li>
          <li><a href='/logout'>Logout</a></li>
        </ul>
      </div>
      
      <div class='admin-content'>
        <form action='/admin/apartments/create' method='post' class='form-card'>
          <div class='form-row'>
            <div class='form-group'>
              <label for='title'>Title</label>
              <input type='text' id='title' name='title' required>
            </div>
            <div class='form-group'>
              <label for='location'>Full Address</label>
              <input type='text' id='location' name='location' required>
            </div>
          </div>
          
          <div class='form-row'>
            <div class='form-group'>
              <label for='neighborhood'>Neighborhood</label>
              <input type='text' id='neighborhood' name='neighborhood' required>
            </div>
            <div class='form-group'>
              <label for='price'>Monthly Rent ($)</label>
              <input type='number' id='price' name='price' min='0' required>
            </div>
          </div>
          
          <div class='form-row'>
            <div class='form-group'>
              <label for='bedrooms'>Bedrooms</label>
              <select id='bedrooms' name='bedrooms' required>
                <option value='0'>Studio</option>
                <option value='1'>1 Bedroom</option>
                <option value='2'>2 Bedrooms</option>
                <option value='3'>3 Bedrooms</option>
                <option value='4'>4 Bedrooms</option>
                <option value='5'>5+ Bedrooms</option>
              </select>
            </div>
            <div class='form-group'>
              <label for='bathrooms'>Bathrooms</label>
              <select id='bathrooms' name='bathrooms' required>
                <option value='1'>1 Bathroom</option>
                <option value='1.5'>1.5 Bathrooms</option>
                <option value='2'>2 Bathrooms</option>
                <option value='2.5'>2.5 Bathrooms</option>
                <option value='3'>3 Bathrooms</option>
                <option value='3.5'>3.5 Bathrooms</option>
                <option value='4'>4+ Bathrooms</option>
              </select>
            </div>
            <div class='form-group'>
              <label for='square_feet'>Square Feet</label>
              <input type='number' id='square_feet' name='square_feet' min='0' required>
            </div>
          </div>
          
          <div class='form-group'>
            <label for='description'>Description</label>
            <textarea id='description' name='description' required></textarea>
          </div>
          
          <div class='form-row'>
            <div class='form-group'>
              <label for='features'>Features (comma separated)</label>
              <input type='text' id='features' name='features' placeholder='e.g. Hardwood floors, Stainless steel appliances, etc.'>
            </div>
            <div class='form-group'>
              <label for='amenities'>Amenities (comma separated)</label>
              <input type='text' id='amenities' name='amenities' placeholder='e.g. Gym, Doorman, Elevator, etc.'>
            </div>
          </div>
          
          <div class='form-row'>
            <div class='form-group'>
              <label for='property_type'>Property Type</label>
              <select id='property_type' name='property_type'>
                <option value='Apartment'>Apartment</option>
                <option value='Condo'>Condo</option>
                <option value='Townhouse'>Townhouse</option>
                <option value='Co-op'>Co-op</option>
              </select>
            </div>
            <div class='form-group'>
              <label for='lease_term'>Lease Term</label>
              <select id='lease_term' name='lease_term'>
                <option value='12 Months'>12 Months</option>
                <option value='24 Months'>24 Months</option>
                <option value='Month-to-Month'>Month-to-Month</option>
              </select>
            </div>
            <div class='form-group'>
              <label for='available_from'>Available From</label>
              <input type='date' id='available_from' name='available_from'>
            </div>
          </div>
          
          <div class='form-row'>
            <div class='form-group'>
              <label for='parking'>Parking</label>
              <input type='text' id='parking' name='parking' placeholder='e.g. Street parking, Garage, etc.'>
            </div>
            <div class='form-group'>
              <label for='utilities_included'>Utilities Included (comma separated)</label>
              <input type='text' id='utilities_included' name='utilities_included' placeholder='e.g. Water, Heat, etc.'>
            </div>
          </div>
          
          <div class='form-row'>
            <div class='form-group'>
              <label for='security_deposit'>Security Deposit ($)</label>
              <input type='number' id='security_deposit' name='security_deposit' min='0'>
            </div>
            <div class='form-group checkbox-group'>
              <input type='checkbox' id='broker_fee' name='broker_fee' value='true'>
              <label for='broker_fee'>Broker Fee Required</label>
            </div>
            <div class='form-group checkbox-group'>
              <input type='checkbox' id='pet_friendly' name='pet_friendly' value='true'>
              <label for='pet_friendly'>Pet Friendly</label>
            </div>
          </div>
          
          <button type='submit' class='btn btn-green'>Create Listing</button>
        </form>
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
  elsif path == "/"
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>SpaceHunter - Apartment Search</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; }
    h1, h2, h3 { color: #515151; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 28px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
    .search-container { background-color: #f9f9f9; padding: 25px; border-radius: 8px; margin-bottom: 30px; border: 1px solid #e0e0e0; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
    .form-group { margin-bottom: 15px; }
    .form-group label { display: block; margin-bottom: 5px; font-weight: bold; color: #515151; }
    .form-group input, .form-group select { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; color: #515151; }
    .form-group input:focus, .form-group select:focus { border-color: #f7b419; outline: none; box-shadow: 0 0 0 2px rgba(247, 180, 25, 0.2); }
    .form-row { display: flex; gap: 15px; }
    .form-row .form-group { flex: 1; }
    .btn { display: inline-block; background: #f7b419; color: #515151; padding: 12px 20px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; 
           font-weight: bold; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
    .btn-search { background: #f7b419; }
    .btn-search:hover { background: #ffc53d; }
    .btn-reset { background: #515151; color: white; }
    .btn-reset:hover { background: #666666; }
    .apartments-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 25px; }
    .apartment-card { border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; transition: all 0.3s ease; background-color: white; }
    .apartment-card:hover { transform: translateY(-5px); box-shadow: 0 10px 20px rgba(0,0,0,0.1); border-color: #f7b419; }
    .apartment-img { height: 200px; background-color: #f7b419; background-position: center; background-size: cover; }
    .apartment-details { padding: 25px; }
    .apartment-price { font-size: 24px; font-weight: bold; color: #f7b419; margin-bottom: 12px; }
    .apartment-location { color: #757575; margin-bottom: 15px; }
    .apartment-features { display: flex; gap: 15px; margin-bottom: 15px; }
    .apartment-feature { display: flex; align-items: center; color: #515151; }
    .apartment-feature strong { color: #515151; }
    .apartment-feature span { margin-left: 5px; }
    .footer { background-color: #515151; color: white; padding: 40px 0; margin-top: 50px; }
    .checkbox-group { display: flex; align-items: center; }
    .checkbox-group input { width: auto; margin-right: 10px; }
    .checkbox-group input:checked { accent-color: #f7b419; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
    </div>
  </header>
  
  <div class='container'>
    <div style='display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;'>
      <h1>Find Your Perfect Apartment</h1>
      <div>
        <a href='/login' class='btn' style='margin-right: 10px;'>Login</a>
        <a href='/admin' class='btn' style='background-color: #e67e22;'>Admin Portal</a>
      </div>
    </div>
    
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
          <div class='form-group'>
            <label for='min_price'>Minimum Price</label>
            <input type='number' id='min_price' name='min_price' placeholder='Enter minimum monthly rent' value='#{query_params['min_price'] || ''}'>
          </div>
          <div class='form-group'>
            <label for='property_type'>Property Type</label>
            <select id='property_type' name='property_type'>
              <option value='' #{query_params['property_type'].nil? || query_params['property_type'].empty? ? 'selected' : ''}>Any</option>
              <option value='Apartment' #{query_params['property_type'] == 'Apartment' ? 'selected' : ''}>Apartment</option>
              <option value='Condo' #{query_params['property_type'] == 'Condo' ? 'selected' : ''}>Condo</option>
              <option value='Townhouse' #{query_params['property_type'] == 'Townhouse' ? 'selected' : ''}>Townhouse</option>
              <option value='Co-op' #{query_params['property_type'] == 'Co-op' ? 'selected' : ''}>Co-op</option>
            </select>
          </div>
          <div class='form-group'>
            <label for='min_square_feet'>Minimum Square Feet</label>
            <input type='number' id='min_square_feet' name='min_square_feet' placeholder='Minimum square footage' value='#{query_params['min_square_feet'] || ''}'>
          </div>
        </div>
        
        <div class='form-row'>
          <div class='form-group'>
            <label for='amenities'>Amenities</label>
            <input type='text' id='amenities' name='amenities' placeholder='E.g. Elevator, Doorman, etc.' value='#{query_params['amenities'] || ''}'>
          </div>
          <div class='form-group'>
            <label for='available_from'>Available From</label>
            <input type='date' id='available_from' name='available_from' value='#{query_params['available_from'] || ''}'>
          </div>
          <div class='form-group'>
            <label for='lease_term'>Lease Term</label>
            <select id='lease_term' name='lease_term'>
              <option value='' #{query_params['lease_term'].nil? || query_params['lease_term'].empty? ? 'selected' : ''}>Any</option>
              <option value='12 Months' #{query_params['lease_term'] == '12 Months' ? 'selected' : ''}>12 Months</option>
              <option value='24 Months' #{query_params['lease_term'] == '24 Months' ? 'selected' : ''}>24 Months</option>
            </select>
          </div>
        </div>
        
        <div class='form-row'>
          <div class='form-group checkbox-group'>
            <input type='checkbox' id='pet_friendly' name='pet_friendly' value='true' #{query_params['pet_friendly'] == 'true' ? 'checked' : ''}>
            <label for='pet_friendly'>Pet Friendly</label>
          </div>
          <div class='form-group checkbox-group'>
            <input type='checkbox' id='no_broker_fee' name='no_broker_fee' value='true' #{query_params['no_broker_fee'] == 'true' ? 'checked' : ''}>
            <label for='no_broker_fee'>No Broker Fee</label>
          </div>
        </div>
        
        <div class='form-row'>
          <button type='submit' class='btn btn-search'>Search</button>
          <a href='/' class='btn btn-reset'>Reset</a>
          <a href='/advanced-search' class='btn' style='background-color: #9b59b6;'>Advanced Search</a>
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
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; }
    h1, h2, h3 { color: #515151; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header .container { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-size: 28px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
    .back-link { display: inline-block; margin-bottom: 20px; color: #f7b419; text-decoration: none; font-weight: bold; }
    .back-link:hover { text-decoration: underline; }
    .apartment-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; }
    .apartment-title h1 { margin: 0; color: #515151; }
    .apartment-price { font-size: 28px; font-weight: bold; color: #f7b419; }
    .apartment-image { height: 400px; background-color: #f7b419; border-radius: 8px; margin-bottom: 30px; }
    .apartment-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 30px; }
    .apartment-details { background-color: #f9f9f9; padding: 25px; border-radius: 8px; border: 1px solid #e0e0e0; }
    .apartment-feature-list { list-style-type: none; padding: 0; }
    .apartment-feature-list li { margin-bottom: 10px; padding-left: 25px; position: relative; }
    .apartment-feature-list li:before { content: '✓'; position: absolute; left: 0; color: #f7b419; font-weight: bold; }
    .contact-form { background-color: #f9f9f9; padding: 25px; border-radius: 8px; border: 1px solid #e0e0e0; }
    .form-group { margin-bottom: 15px; }
    .form-group label { display: block; margin-bottom: 5px; font-weight: bold; color: #515151; }
    .form-group input, .form-group textarea { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; color: #515151; }
    .form-group input:focus, .form-group textarea:focus { border-color: #f7b419; outline: none; box-shadow: 0 0 0 2px rgba(247, 180, 25, 0.2); }
    .btn { display: inline-block; background: #f7b419; color: #515151; padding: 12px 20px; 
           text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; 
           font-weight: bold; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
    .footer { background-color: #515151; color: white; padding: 40px 0; margin-top: 50px; }
    .property-info { display: flex; flex-wrap: wrap; gap: 15px; margin-bottom: 20px; }
    .property-info-item { flex: 1; min-width: 150px; background-color: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }
    .property-info-item strong { display: block; margin-bottom: 5px; font-size: 14px; color: #7f8c8d; }
    .property-info-item span { font-size: 18px; font-weight: bold; color: #515151; }
  </style>
</head>
<body>
  <header class='header'>
    <div class='container'>
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
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
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
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
      <div class='logo'><img src='/images/myspacenyc-logo.png' alt='SpaceHunter Logo' style='height: 40px; margin-right: 10px; vertical-align: middle;'> SpaceHunter</div>
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