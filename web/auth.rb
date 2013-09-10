require 'sinatra'
require 'json'

class PGQuilter::Auth < Sinatra::Base

  %w(get post).each do |method|
    send(method, "/auth/:provider/callback") do |provider|
      auth_result = env['omniauth.auth']
      puts "auth success:"
      puts auth_result
    end
  end

  get '/auth/failure' do
    err = params[:message]
    puts "auth attempt failed: #{err}"
    status 403
  end

end
