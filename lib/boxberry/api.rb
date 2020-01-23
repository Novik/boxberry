require 'httparty'

module Boxberry
  module API

    extend self

    ENDPOINT = "https://api.boxberry.ru/json.php".freeze

    mattr_accessor :token

    def setup
      yield self
    end

    def shipment_available?(zip)
      HTTParty.get(ENDPOINT, { token: token, method: 'zipcheck', zip: zip })
    end

  end
end