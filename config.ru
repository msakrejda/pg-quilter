$stdout.sync = $stderr.sync = true

require 'rubygems'
require 'sinatra/base'

use Rack::CommonLogger

require './lib/pgquilter'
require './web/receiver'

map("/")            { run PGQuilter::Receiver }
