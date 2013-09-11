require 'sequel'

module PGQuilter
  class User < Sequel::Model
    one_to_many :api_tokens
  end
end
