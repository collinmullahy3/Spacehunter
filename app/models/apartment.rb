class Apartment < ApplicationRecord
  validates :title, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :bedrooms, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :bathrooms, numericality: { greater_than_or_equal_to: 0 }
  
  has_many_attached :images
end