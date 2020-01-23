require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class Boxberry < ShippingCalculator

      def self.description
        Spree.t(:shipping_boxberry)
      end

      def compute_package(package)
        290	# any non-zero
      end

      def available?(package)
        false
      rescue
        false
      end
    end
  end
end
