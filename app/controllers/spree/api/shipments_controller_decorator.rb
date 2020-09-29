Spree::Api::ShipmentsController.class_eval do

  def ship
    unless @shipment.shipped?
      if @shipment.shipping_method.boxberry_supported?
        tracking = ::Boxberry::API::create_delivery( @shipment )
        if tracking.present?
          @shipment.update(tracking: tracking)
          flash[:success] = Spree.t(:parsel_boxberry_create_success)
        else
          flash[:error] = Spree.t(:parsel_boxberry_create_fail, reason: ::Boxberry::API::last_error_message)
        end
      end
#      @shipment.ship!
    end
    respond_with(@shipment, default_template: :show)
  end

end
