ENV['DATABASE_URL'] = 'postgres:///pg-quilter'

require './lib/pg-quilter'
require 'rspec'

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
