require 'json'
require 'sequel'
require 'sinatra'
require 'sinatra/base'

$:.unshift File.dirname(__FILE__)

DB = Sequel.connect(ENV['DATABASE_URL'])

require 'pg-quilter/config'
require 'pg-quilter/harness'
require 'pg-quilter/build'
require 'pg-quilter/build_runner'
require 'pg-quilter/task_master'
