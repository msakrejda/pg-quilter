$stdout.sync = $stderr.sync = true

require './lib/pg-quilter'

use Rack::CommonLogger

require './web/receiver'

map("/")            { run PGQuilter::Receiver }
