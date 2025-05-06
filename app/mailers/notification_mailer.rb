class NotificationMailer < ApplicationMailer
  default from: 'notifications@realtymonster.com'
  
  def new_apartment_notification(apartment)
    @apartment = apartment
    @user = apartment.user
    
    mail(
      to: User.where(admin: true).pluck(:email),
      subject: "New Apartment Listing: #{@apartment.title}"
    )
  end
  
  def inquiry_notification(inquiry)
    @inquiry = inquiry
    @apartment = inquiry.apartment
    @owner = @apartment.user
    
    mail(
      to: @owner.email,
      subject: "New Inquiry for #{@apartment.title}"
    )
  end
  
  def status_change_notification(apartment)
    @apartment = apartment
    @user = apartment.user
    
    mail(
      to: @user.email,
      subject: "Status Update for Your Listing: #{@apartment.title}"
    )
  end
end
