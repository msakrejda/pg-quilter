require 'bundler'
Bundler.setup

require './lib/pg-quilter'

namespace :db do
  task :migrate do
    require 'logger'
    require 'sequel'
    require 'sequel/extensions/migration'
    db_url = ENV['DATABASE_URL'] || 'postgres:///pg-quilter'
    target_version = ENV['VERSION'] if ENV['VERSION']
    db = Sequel.connect(db_url, loggers: Logger.new(STDOUT))
    Sequel::Migrator.apply(db, 'migrations', target_version)
  end
end

namespace :worker do
  task :run do
    harness = PGQuilter::Harness.new
    worker = PGQuilter::Worker.new(harness)
    worker.run
  end
end
