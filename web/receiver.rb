require 'sinatra'
require 'json'
require 'mail'

class PGQuilter::Receiver < Sinatra::Base
  post '/mail' do
    PGQuilter::Receiving.handle(params)
    200
  end
end
