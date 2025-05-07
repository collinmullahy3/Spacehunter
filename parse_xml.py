import xml.etree.ElementTree as ET
import json
import os

def parse_property(prop_elem):
    """Parse a single property element from XML"""
    property_data = {
        'id': int(prop_elem.get('id')),
        'type': prop_elem.get('type'),
        'status': prop_elem.get('status'),
        'url': prop_elem.get('url'),
    }
    
    # Parse location data
    location = prop_elem.find('location')
    if location is not None:
        property_data.update({
            'address': get_element_text(location, 'address'),
            'apartment': get_element_text(location, 'apartment'),
            'city': get_element_text(location, 'city'),
            'state': get_element_text(location, 'state'),
            'zipcode': get_element_text(location, 'zipcode'),
            'neighborhood': get_element_text(location, 'neighborhood'),
        })
        
        # Combine address components for display
        full_address = f"{property_data.get('address')}"
        if property_data.get('apartment'):
            full_address += f", Unit {property_data.get('apartment')}"
        full_address += f", {property_data.get('city')}, {property_data.get('state')} {property_data.get('zipcode')}"
        property_data['location'] = full_address
    
    # Parse details
    details = prop_elem.find('details')
    if details is not None:
        # Try to convert price to integer
        price_str = get_element_text(details, 'price')
        try:
            price = int(price_str) if price_str else None
        except:
            price = None
            
        # Try to convert bedrooms and bathrooms to numbers
        bedrooms_str = get_element_text(details, 'bedrooms')
        try:
            bedrooms = int(bedrooms_str) if bedrooms_str else 0
        except:
            bedrooms = 0
            
        bathrooms_str = get_element_text(details, 'bathrooms')
        try:
            bathrooms = float(bathrooms_str) if bathrooms_str else 0
        except:
            bathrooms = 0
        
        property_data.update({
            'title': f"{bedrooms} Bed/{bathrooms} Bath in {property_data.get('neighborhood', 'New York')}",
            'price': price,
            'featured': get_element_text(details, 'featured') == 'yes',
            'rental_term': get_element_text(details, 'rental_term'),
            'utilities': get_element_text(details, 'utilities'),
            'pay_type': get_element_text(details, 'pay_type'),
            'bedrooms': bedrooms,
            'bathrooms': bathrooms,
            'description': get_element_text(details, 'description'),
            'availableOn': get_element_text(details, 'availableOn'),
            'property_type': get_element_text(details, 'propertyType') or get_element_text(details, 'apartment_type'),
            'owner_company_name': get_element_text(details, 'owner_company_name'),
        })
        
        # Set no_broker_fee flag based on pay_type
        property_data['no_broker_fee'] = 'no fee' in property_data.get('pay_type', '').lower()
    
    # Parse amenities
    amenities = prop_elem.find('details/amenities')
    if amenities is not None:
        pets = get_element_text(amenities, 'pets')
        other = get_element_text(amenities, 'other')
        
        property_data['pet_friendly'] = bool(pets and pets.lower() != 'no pets')
        
        # Parse amenities list
        amenities_list = []
        if other:
            amenities_list = [item.strip() for item in other.split(',')]
        property_data['amenities'] = amenities_list
        
        # Extract square footage if available in amenities
        for amenity in amenities_list:
            if 'sq ft' in amenity.lower() or 'sqft' in amenity.lower():
                try:
                    sq_ft = int(''.join(filter(str.isdigit, amenity)))
                    property_data['square_feet'] = sq_ft
                except:
                    pass
    
    # If square_feet not found, provide a reasonable estimate based on bedrooms
    if 'square_feet' not in property_data:
        if property_data.get('bedrooms') == 0:  # Studio
            property_data['square_feet'] = 500
        else:
            property_data['square_feet'] = 500 + (300 * property_data.get('bedrooms', 1))
    
    # Add default features based on amenities
    features = []
    if 'amenities' in property_data:
        features = property_data['amenities']
    
    # Add common features
    if property_data.get('pet_friendly'):
        features.append('Pet Friendly')
    
    if not features and property_data.get('bedrooms', 0) > 0:
        features.append('Spacious Layout')
        features.append('Modern Finishes')
        features.append('Ample Storage')
    
    # Standardize features list
    property_data['features'] = [f for f in features if f]
    
    # Add parking information
    if any('parking' in amenity.lower() for amenity in property_data.get('amenities', [])):
        property_data['parking'] = 'Available'
    else:
        property_data['parking'] = 'Street Parking'
    
    # Images - we don't have image URLs in the XML, but we'd need to handle them
    # Use dummy image for now based on property ID
    property_data['image_url'] = f"/images/apt{property_data['id'] % 5 + 1}.jpg"
    
    return property_data

def get_element_text(parent, element_name):
    """Get text from a child element or empty string if not found"""
    element = parent.find(element_name)
    return element.text.strip() if element is not None and element.text else ""

def parse_xml_file(filename):
    """Parse XML file and return a list of properties"""
    tree = ET.parse(filename)
    root = tree.getroot()
    
    properties = []
    
    for property_elem in root.findall('property'):
        try:
            prop_data = parse_property(property_elem)
            properties.append(prop_data)
        except Exception as e:
            print(f"Error parsing property: {e}")
    
    return properties

def main():
    """Main function to parse XML and output JSON"""
    properties = parse_xml_file('apartments.xml')
    
    # Remove any properties with incomplete data
    filtered_properties = [p for p in properties if p.get('price') and p.get('bedrooms') is not None]
    
    # Sort by price (expensive first)
    sorted_properties = sorted(filtered_properties, key=lambda x: x.get('price', 0), reverse=True)
    
    # Output to JSON file
    with open('apartments.json', 'w') as f:
        json.dump(sorted_properties, f, indent=2)
    
    print(f"Processed {len(sorted_properties)} properties")
    
    # Output a Ruby-compatible representation for our application
    ruby_output = "APARTMENTS = [\n"
    for i, prop in enumerate(sorted_properties[:50]):  # Limit to 50 properties for performance
        ruby_output += "  {\n"
        ruby_output += f"    id: {prop['id']},\n"
        
        # Safe string replacements using single quotes for Ruby strings
        title = prop['title'].replace("'", "\\'")
        location = prop['location'].replace("'", "\\'")
        description = prop['description'].replace("'", "\\'")
        
        ruby_output += f"    title: '{title}',\n"
        ruby_output += f"    location: '{location}',\n"
        ruby_output += f"    price: {prop['price']},\n"
        ruby_output += f"    bedrooms: {prop['bedrooms']},\n"
        ruby_output += f"    bathrooms: {prop['bathrooms']},\n"
        ruby_output += f"    square_feet: {prop['square_feet']},\n"
        ruby_output += f"    description: '{description}',\n"
        
        # Convert features to Ruby array
        features_str = "["
        for j, f in enumerate(prop.get('features', [])):
            escaped_feature = f.replace("'", "\\'")
            features_str += f"'{escaped_feature}'"
            if j < len(prop.get('features', [])) - 1:
                features_str += ", "
        features_str += "]"
        ruby_output += f"    features: {features_str},\n"
        
        available_from = prop.get('availableOn', 'Immediate').replace("'", "\\'")
        neighborhood = prop.get('neighborhood', 'New York').replace("'", "\\'")
        parking = prop.get('parking', 'Street Parking').replace("'", "\\'")
        property_type = prop.get('property_type', 'Apartment').replace("'", "\\'")
        lease_term = prop.get('rental_term', '12 Months').replace("'", "\\'")
        
        ruby_output += f"    available_from: '{available_from}',\n"
        ruby_output += f"    neighborhood: '{neighborhood}',\n"
        ruby_output += f"    pet_friendly: {str(prop.get('pet_friendly', False)).lower()},\n"
        ruby_output += f"    parking: '{parking}',\n"
        ruby_output += f"    image_url: '{prop.get('image_url', '/images/apt1.jpg')}',\n"
        ruby_output += f"    property_type: '{property_type}',\n"
        ruby_output += f"    lease_term: '{lease_term}',\n"
        
        # Add amenities as a string 
        amenities_str = "["
        for j, a in enumerate(prop.get('amenities', [])):
            escaped_amenity = a.replace("'", "\\'")
            amenities_str += f"'{escaped_amenity}'"
            if j < len(prop.get('amenities', [])) - 1:
                amenities_str += ", "
        amenities_str += "]"
        ruby_output += f"    amenities: {amenities_str},\n"
        
        status = prop.get('status', 'Available').replace("'", "\\'")
        ruby_output += f"    status: '{status}',\n"
        ruby_output += f"    last_updated: '2025-04-01',\n"
        ruby_output += f"    broker_fee: {str(not prop.get('no_broker_fee', False)).lower()},\n"
        ruby_output += f"    security_deposit: {prop.get('price', 0)}\n"
        ruby_output += "  }" + ("," if i < len(sorted_properties[:50]) - 1 else "") + "\n"
    
    ruby_output += "]\n"
    
    with open('apartments_data.rb', 'w') as f:
        f.write(ruby_output)
    
    print("Ruby data file created with 50 properties")

if __name__ == "__main__":
    main()