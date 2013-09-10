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

namespace :generate do
  task :token do
    token = PGQuilter::ApiToken.generate
    puts token.secret
  end

  task :migration, :name do |t, args|
    name = args[:name]
    if name.nil?
      raise ArgumentError, "Expected migration name"
    end
    filename = "./migrations/#{Time.now.strftime "%Y%m%d%H%M%S"}_#{name}.rb"
    File.open(filename, 'w') do |file|
      file << <<-FILE
Sequel.migration do
  up do

  end

  down do

  end
end
FILE
    end
    puts "Added #{filename}"
  end
end
