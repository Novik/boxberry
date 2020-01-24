require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class Boxberry < ShippingCalculator

      def self.description
        Spree.t(:shipping_boxberry)
      end

      def compute_package(package)
        Boxberry::API::get_delivery_price( package.try(:order).try(:ship_address).try(:zipcode), package.weight )
      end

      def available?(package)
        Boxberry::API::delivery_available?( package.try(:order).try(:ship_address).try(:zipcode) )
      rescue
        false
      end
    end
  end
end
