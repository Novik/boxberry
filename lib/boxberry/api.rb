require 'httparty'

module Boxberry
  module API

    extend self

    ENDPOINT = "https://api.boxberry.ru/json.php".freeze

    mattr_accessor :token
    mattr_accessor :expires_in
    @@expires_in = 1.hour

    mattr_reader   :last_error

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

    def delivery_available?(zip)
      response = self.get('ZipCheck', { zip: zip }, ['ExpressDelivery'])
      response.present? && (response['ExpressDelivery'].to_i == 1)
    end

    def get_delivery_price(zip,weight = 100)
      self.get('DeliveryCosts', { weight: [weight,100].max, zip: zip }, ['price']).try(:[],'price')
    end

    def get_delivery_period(zip,weight = 100)
      self.get('DeliveryCosts', { weight: [weight,100].max, zip: zip }, ['delivery_period']).try(:[],'delivery_period').try(:to_i)
    end

    def create_delivery()
    end

  end
end