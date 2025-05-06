class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    
    # Guests can only view apartments
    can :read, Apartment
    
    if user.persisted?
      # All logged in users can create apartments
      can :create, Apartment
      
      # Users can manage their own apartments
      can :manage, Apartment, user_id: user.id
      
      # Users can edit their own profile
      can :manage, User, id: user.id
      
      # Admin has full access
      if user.admin?
        can :manage, :all
      end
    end
  end
end