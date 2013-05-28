require 'bundler'
Bundler.setup

namespace :db do
  task :migrate do
    require 'logger'
    require 'sequel'
    require 'sequel/extensions/migration'
    db_url = ENV['DATABASE_URL'] || 'postgres:///pg_quilter'
    target_version = ENV['VERSION'] if ENV['VERSION']
    DB = Sequel.connect(db_url, loggers: Logger.new(STDOUT))
    Sequel::Migrator.apply(DB, 'migrations', target_version)
  end
end

