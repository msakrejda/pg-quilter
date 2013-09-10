require 'sequel'
require 'securerandom'

module PGQuilter
  class ApiToken < Sequel::Model
    def self.generate
      self.create(secret: SecureRandom.hex(32))
    end
    def self.valid?(secret)
      self.where(secret: secret).first
    end
  end
end
