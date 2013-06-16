ENV['DATABASE_URL'] = 'postgres:///pgquilter'
ENV['LOG_LEVEL'] = 'WARN'

require './lib/pgquilter'
require 'rspec'
#require 'rack/test'

RSpec.configure do |config|
  config.order = 'random'
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:each) do

  end

  config.before(:suite) do

  end

  config.after(:each) do

  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
