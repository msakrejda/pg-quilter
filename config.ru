$stdout.sync = $stderr.sync = true

require 'rubygems'
require 'sinatra/base'
require 'rack/timeout'
require 'rack/cache'
require 'rack/csrf'

use Rack::Timeout
Rack::Timeout.timeout = 28

use Rack::Deflater
use Rack::ETag
use Rack::CommonLogger

require './web/api'

map("/")            { run Njobvu::Root }
