require 'sinatra'
require 'json'
require 'mail'

class PGQuilter::Receiver < Sinatra::Base
  post '/mail' do
    PgQuilter::Receiving.process(params)
  end
end
