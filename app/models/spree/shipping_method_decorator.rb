Spree::ShippingMethod.class_eval do

  def boxberry?
    calculator.try(:type)=="Spree::Calculator::Shipping::Boxberry"
  end

end
