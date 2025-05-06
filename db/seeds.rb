# Sample apartments data
apartments = [
  {
    title: 'Luxury Downtown Loft',
    description: 'Beautiful open-concept loft in the heart of downtown with stunning city views and high-end finishes.',
    address: '123 Main St, Apt 501',
    city: 'New York',
    state: 'NY',
    zip: '10001',
    price: 2500.00,
    bedrooms: 1,
    bathrooms: 1.5,
    square_feet: 850,
    available_date: Date.today + 30.days
  },
  {
    title: 'Spacious Family Home',
    description: 'Perfect family home in a quiet suburb with a large backyard, modern kitchen, and plenty of natural light.',
    address: '456 Oak Ave',
    city: 'Chicago',
    state: 'IL',
    zip: '60601',
    price: 3200.00,
    bedrooms: 3,
    bathrooms: 2.0,
    square_feet: 1800,
    available_date: Date.today + 15.days
  },
  {
    title: 'Modern Studio Apartment',
    description: 'Compact and efficient studio with premium amenities, perfect for young professionals.',
    address: '789 Pine St, Unit 3B',
    city: 'San Francisco',
    state: 'CA',
    zip: '94107',
    price: 1800.00,
    bedrooms: 0,
    bathrooms: 1.0,
    square_feet: 500,
    available_date: Date.today
  }
]

apartments.each do |apartment_data|
  Apartment.create!(apartment_data)
end

puts "Created #{Apartment.count} apartments"