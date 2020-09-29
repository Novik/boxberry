Spree::ShippingMethod.class_eval do

  def boxberry_supported?
    boxberry? || self.try(:boxberry_integration)
  end

  def boxberry?
    calculator.try(:type)=="Spree::Calculator::Shipping::Boxberry"
  end

end
