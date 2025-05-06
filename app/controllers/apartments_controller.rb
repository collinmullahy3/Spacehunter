class ApartmentsController < ApplicationController
  def index
    @apartments = Apartment.all
  end

  def show
    @apartment = Apartment.find(params[:id])
  end

  def new
    @apartment = Apartment.new
  end

  def create
    @apartment = Apartment.new(apartment_params)

    if @apartment.save
      redirect_to @apartment, notice: 'Apartment was successfully created.'
    else
      render :new
    end
  end

  def edit
    @apartment = Apartment.find(params[:id])
  end

  def update
    @apartment = Apartment.find(params[:id])

    if @apartment.update(apartment_params)
      redirect_to @apartment, notice: 'Apartment was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @apartment = Apartment.find(params[:id])
    @apartment.destroy
    redirect_to apartments_path, notice: 'Apartment was successfully destroyed.'
  end

  def home
    @featured_apartments = Apartment.limit(3)
  end

  private

  def apartment_params
    params.require(:apartment).permit(:title, :description, :address, :city, :state, :zip, :price, :bedrooms, :bathrooms, :square_feet, :available_date)
  end
end