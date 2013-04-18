$stdout.sync = $stderr.sync = true

require './lib/pgquilter'

use Rack::CommonLogger

require './web/receiver'

map("/")            { run PGQuilter::Receiver }
