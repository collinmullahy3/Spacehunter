require 'socket'
require 'uri'

# Create a simple TCP server that responds to HTTP requests
server = TCPServer.new('0.0.0.0', 5000)
puts "Server started at http://0.0.0.0:5000"

loop do
  client = server.accept
  request_line = client.readline
  
  puts "Received request: #{request_line}"
  
  method, path, http_version = request_line.split
  path = URI.decode_www_form_component(path)
  
  # Set up the response
  if path == "/"
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; color: #333; }
    h1 { color: #2c3e50; }
    .container { max-width: 800px; margin: 0 auto; }
    .card { border: 1px solid #ddd; border-radius: 8px; padding: 20px; margin-bottom: 20px; }
    .btn { display: inline-block; background: #3498db; color: white; padding: 10px 15px; 
           text-decoration: none; border-radius: 4px; }
    .btn:hover { background: #2980b9; }
  </style>
</head>
<body>
  <div class='container'>
    <h1>Welcome to RealtyMonster</h1>
    <p>This is a simple apartment listing application built with Ruby.</p>
    
    <div class='card'>
      <h2>Sample Apartment</h2>
      <p><strong>Location:</strong> New York, NY</p>
      <p><strong>Price:</strong> $3,500/month</p>
      <p><strong>Bedrooms:</strong> 3</p>
      <p><strong>Bathrooms:</strong> 2</p>
      <p>Experience luxury living in this stunning downtown penthouse with panoramic city views...</p>
      <a href='/apartments/1' class='btn'>View Details</a>
    </div>
    
    <p>More features coming soon!</p>
  </div>
</body>
</html>"
  elsif path == "/apartments/1"
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>Luxurious Downtown Penthouse - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; color: #333; }
    h1 { color: #2c3e50; }
    .container { max-width: 800px; margin: 0 auto; }
    .card { border: 1px solid #ddd; border-radius: 8px; padding: 20px; margin-bottom: 20px; }
    .btn { display: inline-block; background: #3498db; color: white; padding: 10px 15px; 
           text-decoration: none; border-radius: 4px; }
    .btn:hover { background: #2980b9; }
    .back-link { display: inline-block; margin-bottom: 20px; }
  </style>
</head>
<body>
  <div class='container'>
    <a href='/' class='back-link'>&lt; Back to Home</a>
    
    <h1>Luxurious Downtown Penthouse</h1>
    
    <div class='card'>
      <p><strong>Location:</strong> 123 Main Street, New York, NY 10001</p>
      <p><strong>Price:</strong> $3,500/month</p>
      <p><strong>Bedrooms:</strong> 3</p>
      <p><strong>Bathrooms:</strong> 2</p>
      <p><strong>Square Feet:</strong> 1,800</p>
      
      <h3>Description</h3>
      <p>Experience luxury living in this stunning downtown penthouse with panoramic city views. 
      This spacious 3-bedroom apartment features high-end finishes, a gourmet kitchen with 
      stainless steel appliances, and a private balcony perfect for entertaining.</p>
      
      <h3>Features</h3>
      <ul>
        <li>Hardwood flooring throughout</li>
        <li>Floor-to-ceiling windows</li>
        <li>Central air conditioning</li>
        <li>In-unit washer and dryer</li>
        <li>24-hour doorman</li>
        <li>Fitness center access</li>
      </ul>
      
      <h3>Available From</h3>
      <p>October 1, 2023</p>
    </div>
  </div>
</body>
</html>"
  else
    response_content = "<!DOCTYPE html>
<html>
<head>
  <title>Page Not Found - RealtyMonster</title>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; color: #333; text-align: center; }
    h1 { color: #e74c3c; }
    .container { max-width: 600px; margin: 0 auto; }
    .btn { display: inline-block; background: #3498db; color: white; padding: 10px 15px; 
           text-decoration: none; border-radius: 4px; margin-top: 20px; }
  </style>
</head>
<body>
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