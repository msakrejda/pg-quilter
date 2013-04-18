require 'sinatra'
require 'json'
require 'mail'

class PGQuilter::Receiver < Sinatra::Base
  post '/mail' do
    mail = Mail.new(params[:message])
    PgQuilter::Receiving.process(mail)
  end
end
