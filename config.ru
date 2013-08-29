$stdout.sync = $stderr.sync = true

require './lib/pg-quilter'

use Rack::CommonLogger

require './web/builder'

map("/v1") { run PGQuilter::Builder }
