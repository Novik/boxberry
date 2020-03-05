require 'httparty'

module Boxberry
  module API

    extend self

    ENDPOINT = "https://api.boxberry.ru/json.php".freeze
    
    MIN_WEIGHT = 100

    mattr_accessor :token
    mattr_accessor :expires_in
    @@expires_in = 1.hour

    mattr_reader   :last_error

    def setup
      yield self
    end

    def last_error_message
      @@last_error || ""
    end

    def delivery_available?(zip)
      response = get('ZipCheck', { zip: zip }, ['ExpressDelivery'])
      response.present? && (response['ExpressDelivery'].to_i == 1)
    end

    def get_delivery_price(zip,weight = MIN_WEIGHT)
      get('DeliveryCosts', { weight: [weight,MIN_WEIGHT].max, zip: zip }, ['price']).try(:[],'price')
    end

    def get_delivery_period(zip,weight = MIN_WEIGHT)
      get('DeliveryCosts', { weight: [weight,MIN_WEIGHT].max, zip: zip }, ['delivery_period']).try(:[],'delivery_period').try(:to_i)
    end

    def create_delivery( shipment )
      ret = post('ParselCreate', get_parcel_parameters( shipment ), ['track'])
      ret.present? ? ret['track'] : nil
    end

    protected

    def get_payment_cost( shipment )
      [shipment.order.total - shipment.order.payments.completed.sum(:amount),0].max # remove prepaid money
    end

    def has_free_shipping?( order )
      promotions = Spree::Promotion.active.where( id: Spree::Promotion::Actions::FreeShipping.pluck(:promotion_id), path: nil )
      promotions.detect { |promotion| promotion.eligible?(order) }.present?
    end

    def get_shipment_cost( shipment )
      has_free_shipping?( shipment.order ) ? 0 : shipment.selected_shipping_rate.cost
    end

    def get_parcel_parameters( shipment )
      order = shipment.order
      address = order.ship_address
      parsel = 
      {
        order_id: order.number,
        price: order.total.to_i,
        payment_sum: get_payment_cost( shipment ),
        delivery_sum: get_shipment_cost( shipment ),
        vid: 2, # courier
        kurdost:
        {
          index: address.zipcode,
          citi: "#{address.state_text}, #{address.city}",
          addressp: address.address1
        },
        customer:
        {
          fio: address.full_name,
          phone: address.phone.to_s.gsub(/[^0-9]/, ""),
          email: order.email
        },
        items: [],
        weights: {}
      }

      weight = 0
      shipment.inventory_units.preload(:variant).each_with_index do |iu,index|
        v = iu.variant
        parsel[:items].push(
        {
          name: v.name,
          nds: 0,
          price: v.price.to_i,
          quantity: 1
        })
        weight += v.weight
      end
      parsel[:weights][:weight] = [(weight*1000).to_i,MIN_WEIGHT].max
      parsel
    end

    def post( method, attrs = {}, answer_keys = [] )
      @@last_error = nil
      response = HTTParty.post(ENDPOINT, body: { token: @@token }.merge(method: method).merge(attrs), format: :json)
      response = response.parsed_response
      if response.is_a?(Hash)
        raise response["err"] if response.key?('err')
        raise "incorrect API answer" if answer_keys.any? && (answer_keys - response.keys).any?
      else    
        raise "incorrect API answer" if answer_keys.any?
      end
      response
    rescue HTTParty::Error, StandardError => e
      @@last_error = e.message
      nil
    end

    def get( method, attrs = {}, answer_keys = [] )
      @@last_error = nil
      query = { method: method }.merge(attrs)
      key = query.to_s.parameterize
      raw_response = Rails.cache.read( key )
      if raw_response.nil?
        response = HTTParty.get(ENDPOINT, query: query.merge( token: @@token ), format: :json)
        raw_response = response.to_s
        Rails.cache.write( key, raw_response, expires_in: @@expires_in  ) if response.success?
      end
      response = JSON.parse(raw_response)
      response = response[0] if response.is_a?(Array)
      if response.is_a?(Hash) 
        raise response["err"] if response.key?('err')
        raise "incorrect API answer" if answer_keys.any? && (answer_keys - response.keys).any?
      else    
        raise "incorrect API answer" if answer_keys.any?
      end
      response
    rescue HTTParty::Error, StandardError => e
      @@last_error = e.message
      nil
    end

  end
end