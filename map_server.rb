require 'socket'
require 'uri'
require 'json'

# Site configuration
SITE_NAME = "SpaceHunter"
LOGO_HTML = "SpaceHunter"

# In-memory database for apartments - from XML feed
require_relative './apartments_data'

# Add fallback image URLs if needed
APARTMENTS.each do |apt|
  apt_id = apt[:id] % 5 + 1
  apt[:image_url] ||= "/images/apt#{apt_id}.jpg"
end

# Apartment filtering
def filter_apartments(params)
  filtered = APARTMENTS.dup
  
  # Filter by neighborhood
  if params['neighborhood'] && !params['neighborhood'].empty?
    search_term = params['neighborhood'].downcase
    filtered = filtered.select { |apt| apt[:neighborhood].to_s.downcase.include?(search_term) || apt[:location].to_s.downcase.include?(search_term) }
  end
  
  # Filter by minimum bedrooms
  if params['min_bedrooms'] && !params['min_bedrooms'].empty?
    min_bedrooms = params['min_bedrooms'].to_i
    filtered = filtered.select { |apt| apt[:bedrooms] >= min_bedrooms }
  end
  
  # Filter by maximum price
  if params['max_price'] && !params['max_price'].empty?
    max_price = params['max_price'].to_i
    filtered = filtered.select { |apt| apt[:price] <= max_price }
  end
  
  # Filter by minimum price
  if params['min_price'] && !params['min_price'].empty?
    min_price = params['min_price'].to_i
    filtered = filtered.select { |apt| apt[:price] >= min_price }
  end
  
  # Filter by property type
  if params['property_type'] && !params['property_type'].empty?
    filtered = filtered.select { |apt| apt[:property_type] == params['property_type'] }
  end
  
  # Filter by minimum square feet
  if params['min_square_feet'] && !params['min_square_feet'].empty?
    min_square_feet = params['min_square_feet'].to_i
    filtered = filtered.select { |apt| apt[:square_feet] >= min_square_feet }
  end
  
  # Filter by amenities
  if params['amenities'] && !params['amenities'].empty?
    amenities = params['amenities'].downcase.split(',').map(&:strip)
    filtered = filtered.select do |apt|
      amenities.all? do |amenity|
        apt[:amenities].any? { |a| a.to_s.downcase.include?(amenity) }
      end
    end
  end
  
  # Filter by pet friendly
  if params['pet_friendly'] == 'true'
    filtered = filtered.select { |apt| apt[:pet_friendly] }
  end
  
  # Filter by no broker fee
  if params['no_broker_fee'] == 'true'
    filtered = filtered.select { |apt| !apt[:broker_fee] }
  end
  
  filtered
end

# Parse query string parameters
def parse_query_params(query_string)
  params = {}
  return params unless query_string && !query_string.empty?
  
  pairs = query_string.split('&')
  pairs.each do |pair|
    key, value = pair.split('=')
    params[URI.decode_www_form_component(key)] = URI.decode_www_form_component(value || '')
  end
  
  params
end

# Start the server
server = TCPServer.new('0.0.0.0', 5000)
puts "Server started at http://localhost:5000"

loop do
  client = server.accept
  
  # Read the request
  request_line = client.gets
  next unless request_line
  
  # Parse the request line
  method, full_path, http_version = request_line.split
  path, query_string = full_path.split('?', 2)
  
  # Read headers
  headers = {}
  while (line = client.gets.chomp) != ''
    key, value = line.split(': ', 2)
    headers[key.downcase] = value
  end
  
  # Read request body if it exists
  body = ''
  if headers['content-length']
    content_length = headers['content-length'].to_i
    body = client.read(content_length)
  end
  
  # Parse query parameters
  query_params = parse_query_params(query_string)
  
  # Determine response content based on path
  if path == "/"
    response_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>SpaceHunter - Apartment Search</title>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCVKSrcCGIsG5183AchUeq2js4HZSuIPIE"></script>
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
          .apartments-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 25px; }
          .apartment-card { border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; transition: all 0.3s ease; background-color: white; }
          .apartment-card:hover { transform: translateY(-5px); box-shadow: 0 10px 20px rgba(0,0,0,0.1); border-color: #f7b419; }
          .apartment-img { height: 200px; background-color: #f7b419; background-position: center; background-size: cover; background-repeat: no-repeat; }
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
          .top-section { display: flex; flex-direction: column; gap: 30px; margin-bottom: 30px; }
          .filters-container { width: 100%; }
          .map-container { width: 100%; height: 600px; border-radius: 8px; overflow: hidden; }
          #map { width: 100%; height: 100%; border-radius: 8px; border: 1px solid #e0e0e0; }
          .apartments-section { width: 100%; }
        </style>
      </head>
      <body>
        <header class='header'>
          <div class='container'>
            <div class='logo'>SpaceHunter</div>
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
          
          <div class='top-section'>
            <div class='map-container'>
              <h2>Map View</h2>
              <div id='map'></div>
            </div>
            
            <div class='filters-container'>
              <div class='search-container'>
                <h2>Search Filters</h2>
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
                  </div>
                  
                  <div class='form-row'>
                    <div class='form-group'>
                      <label for='min_price'>Minimum Price</label>
                      <input type='number' id='min_price' name='min_price' placeholder='Enter minimum monthly rent' value='#{query_params['min_price'] || ''}'>
                    </div>
                    <div class='form-group'>
                      <label for='max_price'>Maximum Price</label>
                      <input type='number' id='max_price' name='max_price' placeholder='Enter maximum monthly rent' value='#{query_params['max_price'] || ''}'>
                    </div>
                  </div>
                  
                  <div class='form-row'>
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
            </div>
          </div>
          
          <div class='apartments-section'>
            <h2>Available Apartments</h2>
            <div class='apartments-grid'>
    HTML
    
    # Filter apartments based on query parameters
    apartments = filter_apartments(query_params)
    
    if apartments.empty?
      response_content += <<~HTML
              <div style='grid-column: 1 / -1; text-align: center; padding: 30px;'>
                <h3>No apartments match your search criteria</h3>
                <p>Try adjusting your filters or <a href='/'>view all apartments</a>.</p>
              </div>
      HTML
    else
      apartments.each do |apt|
        image_url = apt[:image_url].to_s
        
        # Use img tag instead of background-image to handle complex URLs
        response_content += <<~HTML
              <div class='apartment-card'>
                <div class='apartment-img'>
                  <img src="#{image_url}" alt="#{apt[:title]}" style="width: 100%; height: 100%; object-fit: cover;">
                </div>
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
              </div>
        HTML
      end
    end
    
    response_content += <<~HTML
            </div>
          </div>
        </div>
        
        <script>
          var map;
          
          // Initialize the map when window loads
          window.onload = function() {
            // Default center of the map (New York City)
            var center = { lat: 40.7128, lng: -74.0060 };
            
            // Create the map
            map = new google.maps.Map(document.getElementById('map'), {
              zoom: 12,
              center: center,
              mapTypeControl: true,
              streetViewControl: false,
              fullscreenControl: true
            });
            
            // Add markers for each apartment
            var apartments = [
              #{apartments.map { |apt| 
                # Extract approximate coordinates from the location (simplified for demo)
                lat = 40.7128 + (apt[:id] * 0.01 - 0.03)
                lng = -74.0060 + (apt[:id] * 0.005 - 0.01)
                
                "{ id: #{apt[:id]}, title: '#{apt[:title].to_s.gsub("'", "\\\\'")}', position: { lat: #{lat}, lng: #{lng} }, price: #{apt[:price]} }"
              }.join(",\n              ")}
            ];
            
            // Add markers to the map
            for(var i = 0; i < apartments.length; i++) {
              var apt = apartments[i];
              var marker = new google.maps.Marker({
                position: apt.position,
                map: map,
                title: apt.title
              });
              
              // Create info window content
              var content = '<div style="max-width: 200px; padding: 10px;">' +
                '<h3 style="margin-top: 0; color: #515151;">' + apt.title + '</h3>' +
                '<p style="font-weight: bold; color: #f7b419;">$' + apt.price + '/month</p>' +
                '<a href="/apartments/' + apt.id + '" style="display: inline-block; background: #f7b419; color: #515151; padding: 8px 12px; ' +
                'text-decoration: none; border-radius: 4px; font-weight: bold; margin-top: 10px;">View Details</a>' +
                '</div>';
              
              // Create info window
              var infoWindow = new google.maps.InfoWindow({
                content: content
              });
              
              // Add click listener to open info window
              (function(marker, infoWindow) {
                marker.addListener('click', function() {
                  infoWindow.open(map, marker);
                });
              })(marker, infoWindow);
            }
          };
        </script>
        
        <footer class='footer'>
          <div class='container'>
            <p>&copy; 2025 SpaceHunter. All rights reserved.</p>
          </div>
        </footer>
      </body>
      </html>
    HTML
  elsif path.start_with?("/apartments/")
    # Extract apartment ID from the path
    apartment_id = path.split('/').last.to_i
    apartment = APARTMENTS.find { |apt| apt[:id] == apartment_id }
    
    if apartment
      # Get the image URL for the apartment
      image_url = apartment[:image_url].to_s
      
      response_content = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>SpaceHunter</title>
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
              <div class='logo'>SpaceHunter</div>
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
            
            <div class='apartment-image'>
              <img src="#{image_url}" alt="#{apartment[:title]}" style="width: 100%; height: 100%; object-fit: cover; border-radius: 8px;">
            </div>
            
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
              <p>&copy; 2025 SpaceHunter. All rights reserved.</p>
            </div>
          </footer>
        </body>
        </html>
      HTML
    else
      # Apartment not found
      response_content = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>SpaceHunter</title>
          <meta charset='UTF-8'>
          <meta name='viewport' content='width=device-width, initial-scale=1.0'>
          <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #333; text-align: center; }
            h1 { color: #515151; }
            .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
            .btn { display: inline-block; background: #f7b419; color: #515151; padding: 10px 15px; 
                   text-decoration: none; border-radius: 4px; margin-top: 20px; }
            .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; }
            .logo { font-size: 24px; font-weight: bold; }
          </style>
        </head>
        <body>
          <header class='header'>
            <div class='container'>
              <div class='logo'>SpaceHunter</div>
            </div>
          </header>
          
          <div class='container'>
            <h1>Apartment Not Found</h1>
            <p>Sorry, the apartment you are looking for does not exist or may have been removed.</p>
            <a href='/' class='btn'>Back to All Apartments</a>
          </div>
        </body>
        </html>
      HTML
    end
  elsif path == "/admin" || path.start_with?("/admin/")
    # Simple Admin Authentication (In a real app, we would use proper authentication)
    admin_authenticated = true
    
    if admin_authenticated
      current_tab = "properties"
      
      # Check if a specific tab is requested
      if path == "/admin/users"
        current_tab = "users"
      elsif path == "/admin/settings"
        current_tab = "settings"
      end
      
      response_content = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>SpaceHunter Admin</title>
          <meta charset='UTF-8'>
          <meta name='viewport' content='width=device-width, initial-scale=1.0'>
          <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; background-color: #f5f5f5; }
            h1, h2, h3 { color: #515151; }
            .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
            .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header .container { display: flex; justify-content: space-between; align-items: center; }
            .logo { font-size: 24px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
            .admin-panel { display: flex; gap: 30px; }
            .sidebar { width: 250px; background-color: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
            .main-content { flex: 1; background-color: white; border-radius: 8px; padding: 25px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
            .nav-link { display: block; padding: 12px 15px; color: #515151; text-decoration: none; border-radius: 4px; margin-bottom: 5px; font-weight: 500; }
            .nav-link:hover { background-color: #f5f5f5; }
            .nav-link.active { background-color: #f7b419; color: #515151; font-weight: bold; }
            .stats-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
            .stat-card { background-color: #f9f9f9; border-radius: 8px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); text-align: center; }
            .stat-number { font-size: 36px; font-weight: bold; color: #f7b419; margin: 10px 0; }
            .stat-label { font-size: 14px; color: #757575; }
            .btn { display: inline-block; background: #f7b419; color: #515151; padding: 10px 15px; 
                   text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 14px; 
                   font-weight: bold; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
            .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
            table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
            th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #e0e0e0; }
            th { background-color: #f5f5f5; font-weight: bold; color: #515151; }
            tr:hover { background-color: #f9f9f9; }
            .actions { display: flex; gap: 10px; }
            .edit-btn { color: #3498db; }
            .delete-btn { color: #e74c3c; }
            .tab-content { display: none; }
            .tab-content.active { display: block; }
            .form-group { margin-bottom: 15px; }
            .form-group label { display: block; margin-bottom: 5px; font-weight: bold; color: #515151; }
            .form-group input, .form-group select, .form-group textarea { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; color: #515151; }
            .form-row { display: flex; gap: 15px; margin-bottom: 15px; }
            .form-row .form-group { flex: 1; }
          </style>
        </head>
        <body>
          <header class='header'>
            <div class='container'>
              <div class='logo'>SpaceHunter Admin</div>
              <div>
                <a href='/' class='btn' style='margin-right: 10px;'>View Site</a>
                <a href='/logout' class='btn' style='background-color: #515151; color: white;'>Logout</a>
              </div>
            </div>
          </header>
          
          <div class='container'>
            <div class='admin-panel'>
              <div class='sidebar'>
                <a href='/admin' class='nav-link #{current_tab == "properties" ? "active" : ""}'>Properties</a>
                <a href='/admin/users' class='nav-link #{current_tab == "users" ? "active" : ""}'>Users</a>
                <a href='/admin/settings' class='nav-link #{current_tab == "settings" ? "active" : ""}'>Settings</a>
                <div style='margin-top: 30px;'>
                  <a href='/admin/reports' class='nav-link'>Reports</a>
                  <a href='/admin/inquiries' class='nav-link'>Inquiries</a>
                </div>
              </div>
              
              <div class='main-content'>
                <div id='properties-tab' class='tab-content #{current_tab == "properties" ? "active" : ""}'>
                  <div style='display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;'>
                    <h2>Property Management</h2>
                    <a href='/admin/properties/new' class='btn'>Add New Property</a>
                  </div>
                  
                  <div class='stats-grid'>
                    <div class='stat-card'>
                      <div class='stat-label'>Total Properties</div>
                      <div class='stat-number'>#{APARTMENTS.length}</div>
                    </div>
                    <div class='stat-card'>
                      <div class='stat-label'>Active Listings</div>
                      <div class='stat-number'>#{APARTMENTS.length}</div>
                    </div>
                    <div class='stat-card'>
                      <div class='stat-label'>Avg. Rent Price</div>
                      <div class='stat-number'>$#{APARTMENTS.map { |apt| apt[:price] }.sum / APARTMENTS.length}</div>
                    </div>
                    <div class='stat-card'>
                      <div class='stat-label'>Inquiries This Month</div>
                      <div class='stat-number'>24</div>
                    </div>
                  </div>
                  
                  <table>
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Property</th>
                        <th>Location</th>
                        <th>Price</th>
                        <th>Beds/Baths</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      #{APARTMENTS.first(10).map { |apt| 
                        "<tr>
                          <td>#{apt[:id]}</td>
                          <td>#{apt[:title]}</td>
                          <td>#{apt[:location]}</td>
                          <td>$#{apt[:price]}</td>
                          <td>#{apt[:bedrooms]}/#{apt[:bathrooms]}</td>
                          <td class='actions'>
                            <a href='/admin/properties/#{apt[:id]}/edit' class='edit-btn'>Edit</a>
                            <a href='/admin/properties/#{apt[:id]}/delete' class='delete-btn'>Delete</a>
                          </td>
                        </tr>"
                      }.join("\n                      ")}
                    </tbody>
                  </table>
                  
                  <div style='text-align: center;'>
                    <a href='/admin/properties' class='btn'>View All Properties</a>
                  </div>
                </div>
                
                <div id='users-tab' class='tab-content #{current_tab == "users" ? "active" : ""}'>
                  <div style='display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;'>
                    <h2>User Management</h2>
                    <a href='/admin/users/new' class='btn'>Add New User</a>
                  </div>
                  
                  <div class='stats-grid'>
                    <div class='stat-card'>
                      <div class='stat-label'>Total Users</div>
                      <div class='stat-number'>85</div>
                    </div>
                    <div class='stat-card'>
                      <div class='stat-label'>New This Month</div>
                      <div class='stat-number'>12</div>
                    </div>
                    <div class='stat-card'>
                      <div class='stat-label'>Active Now</div>
                      <div class='stat-number'>8</div>
                    </div>
                    <div class='stat-card'>
                      <div class='stat-label'>Admins</div>
                      <div class='stat-number'>3</div>
                    </div>
                  </div>
                  
                  <table>
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Joined</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>1</td>
                        <td>Admin User</td>
                        <td>admin@spacehunter.com</td>
                        <td>Administrator</td>
                        <td>Jan 15, 2023</td>
                        <td class='actions'>
                          <a href='/admin/users/1/edit' class='edit-btn'>Edit</a>
                          <a href='/admin/users/1/delete' class='delete-btn'>Delete</a>
                        </td>
                      </tr>
                      <tr>
                        <td>2</td>
                        <td>Jane Smith</td>
                        <td>jane@example.com</td>
                        <td>Agent</td>
                        <td>Mar 22, 2023</td>
                        <td class='actions'>
                          <a href='/admin/users/2/edit' class='edit-btn'>Edit</a>
                          <a href='/admin/users/2/delete' class='delete-btn'>Delete</a>
                        </td>
                      </tr>
                      <tr>
                        <td>3</td>
                        <td>John Doe</td>
                        <td>john@example.com</td>
                        <td>Customer</td>
                        <td>Apr 10, 2023</td>
                        <td class='actions'>
                          <a href='/admin/users/3/edit' class='edit-btn'>Edit</a>
                          <a href='/admin/users/3/delete' class='delete-btn'>Delete</a>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                  
                  <div style='text-align: center;'>
                    <a href='/admin/users' class='btn'>View All Users</a>
                  </div>
                </div>
                
                <div id='settings-tab' class='tab-content #{current_tab == "settings" ? "active" : ""}'>
                  <h2>System Settings</h2>
                  
                  <form action='/admin/settings/save' method='post'>
                    <div class='form-row'>
                      <div class='form-group'>
                        <label for='site_name'>Site Name</label>
                        <input type='text' id='site_name' name='site_name' value='SpaceHunter'>
                      </div>
                      <div class='form-group'>
                        <label for='support_email'>Support Email</label>
                        <input type='email' id='support_email' name='support_email' value='support@spacehunter.com'>
                      </div>
                    </div>
                    
                    <div class='form-group'>
                      <label for='description'>Site Description</label>
                      <textarea id='description' name='description' rows='3'>SpaceHunter is a premium apartment rental platform for finding your perfect home.</textarea>
                    </div>
                    
                    <h3>Appearance</h3>
                    <div class='form-row'>
                      <div class='form-group'>
                        <label for='primary_color'>Primary Color</label>
                        <input type='color' id='primary_color' name='primary_color' value='#f7b419'>
                      </div>
                      <div class='form-group'>
                        <label for='secondary_color'>Secondary Color</label>
                        <input type='color' id='secondary_color' name='secondary_color' value='#515151'>
                      </div>
                    </div>
                    
                    <h3>API Integrations</h3>
                    <div class='form-group'>
                      <label for='google_maps_api_key'>Google Maps API Key</label>
                      <input type='text' id='google_maps_api_key' name='google_maps_api_key' value='AIzaSyCVKSrcCGIsG5183AchUeq2js4HZSuIPIE'>
                    </div>
                    
                    <div class='form-group'>
                      <label for='enable_analytics'>Enable Analytics</label>
                      <select id='enable_analytics' name='enable_analytics'>
                        <option value='1' selected>Yes</option>
                        <option value='0'>No</option>
                      </select>
                    </div>
                    
                    <button type='submit' class='btn'>Save Settings</button>
                  </form>
                </div>
              </div>
            </div>
          </div>
        </body>
        </html>
      HTML
    else
      # Admin login page
      response_content = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>SpaceHunter Admin Login</title>
          <meta charset='UTF-8'>
          <meta name='viewport' content='width=device-width, initial-scale=1.0'>
          <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; background-color: #f5f5f5; }
            .login-container { max-width: 400px; margin: 100px auto; padding: 30px; background-color: white; border-radius: 8px; box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
            h1 { text-align: center; color: #515151; margin-bottom: 30px; }
            .form-group { margin-bottom: 20px; }
            .form-group label { display: block; margin-bottom: 5px; font-weight: bold; color: #515151; }
            .form-group input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; color: #515151; box-sizing: border-box; }
            .form-group input:focus { border-color: #f7b419; outline: none; box-shadow: 0 0 0 2px rgba(247, 180, 25, 0.2); }
            .btn { display: block; width: 100%; background: #f7b419; color: #515151; padding: 12px 20px; 
                   text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; 
                   font-weight: bold; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
            .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
            .back-link { display: block; text-align: center; margin-top: 20px; color: #515151; text-decoration: none; }
            .back-link:hover { text-decoration: underline; }
            .logo { font-size: 28px; font-weight: bold; text-align: center; margin-bottom: 20px; color: #f7b419; }
          </style>
        </head>
        <body>
          <div class='login-container'>
            <div class='logo'>SpaceHunter</div>
            <h1>Admin Login</h1>
            <form action='/admin/login' method='post'>
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
            <a href='/' class='back-link'>Back to Website</a>
          </div>
        </body>
        </html>
      HTML
    end
  elsif path == "/login"
    # User login page
    response_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>SpaceHunter Login</title>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #515151; background-color: #f5f5f5; }
          .login-container { max-width: 400px; margin: 100px auto; padding: 30px; background-color: white; border-radius: 8px; box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
          h1 { text-align: center; color: #515151; margin-bottom: 30px; }
          .form-group { margin-bottom: 20px; }
          .form-group label { display: block; margin-bottom: 5px; font-weight: bold; color: #515151; }
          .form-group input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; color: #515151; box-sizing: border-box; }
          .form-group input:focus { border-color: #f7b419; outline: none; box-shadow: 0 0 0 2px rgba(247, 180, 25, 0.2); }
          .btn { display: block; width: 100%; background: #f7b419; color: #515151; padding: 12px 20px; 
                 text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; 
                 font-weight: bold; transition: all 0.3s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
          .btn:hover { background: #ffc53d; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
          .back-link { display: block; text-align: center; margin-top: 20px; color: #515151; text-decoration: none; }
          .back-link:hover { text-decoration: underline; }
          .logo { font-size: 28px; font-weight: bold; text-align: center; margin-bottom: 20px; color: #f7b419; }
          .signup-link { display: block; text-align: center; margin-top: 20px; color: #515151; }
        </style>
      </head>
      <body>
        <div class='login-container'>
          <div class='logo'>SpaceHunter</div>
          <h1>User Login</h1>
          <form action='/login' method='post'>
            <div class='form-group'>
              <label for='email'>Email</label>
              <input type='email' id='email' name='email' required>
            </div>
            <div class='form-group'>
              <label for='password'>Password</label>
              <input type='password' id='password' name='password' required>
            </div>
            <button type='submit' class='btn'>Login</button>
          </form>
          <div class='signup-link'>
            Don't have an account? <a href='/signup'>Sign up</a>
          </div>
          <a href='/' class='back-link'>Back to Website</a>
        </div>
      </body>
      </html>
    HTML
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
    response_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>SpaceHunter</title>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.6; color: #333; text-align: center; }
          h1 { color: #515151; }
          .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
          .btn { display: inline-block; background: #f7b419; color: #515151; padding: 10px 15px; 
                 text-decoration: none; border-radius: 4px; margin-top: 20px; }
          .header { background-color: #f7b419; color: #515151; padding: 20px 0; margin-bottom: 30px; }
          .logo { font-size: 24px; font-weight: bold; }
        </style>
      </head>
      <body>
        <header class='header'>
          <div class='container'>
            <div class='logo'>SpaceHunter</div>
          </div>
        </header>
        
        <div class='container'>
          <h1>404 - Page Not Found</h1>
          <p>The page you are looking for does not exist.</p>
          <a href='/' class='btn'>Back to Home</a>
        </div>
      </body>
      </html>
    HTML
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