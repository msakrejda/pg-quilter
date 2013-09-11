require 'json'
require 'sequel'
require 'sequel/extensions/pg_hstore'
require 'sinatra'
require 'sinatra/base'

$:.unshift File.dirname(__FILE__)

DB = Sequel.connect(ENV['DATABASE_URL'])
DB.extension :pg_hstore

require 'pg-quilter/config'
require 'pg-quilter/harness'
require 'pg-quilter/build'
require 'pg-quilter/build_runner'
require 'pg-quilter/task_master'
require 'pg-quilter/api_token'
require 'pg-quilter/user'
require 'pg-quilter/worker'
