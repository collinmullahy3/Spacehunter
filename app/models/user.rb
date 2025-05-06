class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :apartments, dependent: :destroy
  
  # User roles
  ROLES = %w[admin landlord renter].freeze
  
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }
  
  # Active Storage for profile image
  has_one_attached :avatar
  
  def admin?
    role == 'admin'
  end
  
  def landlord?
    role == 'landlord'
  end
  
  def renter?
    role == 'renter'
  end
end