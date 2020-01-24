Spree::ShippingRate.class_eval do
 
  delegate :boxberry?, to: :shipping_method

  def cost
    if shipping_method.try(:boxberry?)
      Boxberry::API::get_delivery_price( shipment.try(:order).try(:ship_address).try(:zipcode), 
        shipment.inventory_units.joins(:variant).sum(:weight) )
    else
      self[:cost]
    end
  end

  def period
    if shipping_method.try(:boxberry?)
      Boxberry::API::get_delivery_period( shipment.try(:order).try(:ship_address).try(:zipcode), 
        shipment.inventory_units.joins(:variant).sum(:weight) )
    else
      nil
    end
  end

end
