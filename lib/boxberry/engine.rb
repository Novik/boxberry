module Boxberry
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'boxberry'

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc

    initializer "spree.boxberry.shipment_methods", :after => "spree.register.shipment_methods" do |app|
      app.config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::Boxberry
    end
  end
end
