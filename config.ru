$stdout.sync = $stderr.sync = true

require 'omniauth'
require 'omniauth-github'

require './lib/pg-quilter'

use Rack::CommonLogger

require './web/builder'
require './web/auth'

map("/v1") { run PGQuilter::Builder }
map("/") do

  use Rack::Session::Cookie, secret: ENV['RACK_COOKIE_SECRET']

  use OmniAuth::Builder do
    provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET']
  end

  run PGQuilter::Auth
end
