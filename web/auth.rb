require 'sinatra'
require 'json'

class PGQuilter::Auth < Sinatra::Base

  before do
    unless request.path_info == '/'
      if session[:user_id].nil?
        redirect '/auth/github'
      end
    end
    @user_name ||= session[:user_name]
  end

  %w(get post).each do |method|
    send(method, "/auth/:provider/callback") do |provider|
      auth = env['omniauth.auth']

      user = PGQuilter::User.find_or_create(provider: auth.provider, uid: auth.uid)
      session[:user_id] = user.uuid
      session[:user_name] = auth.info.name

      redirect '/admin'
    end
  end

  def user
    @user ||= User[session[:user_id]]
  end

  get '/auth/failure' do
    err = params[:message]
    puts "auth attempt failed: #{err}"
    status 403
  end

  get '/admin' do
    erb :admin
  end

  get '/' do
    erb :intro
  end

end
