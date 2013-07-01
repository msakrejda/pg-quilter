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
    DB = Sequel.connect(db_url, loggers: Logger.new(STDOUT))
    Sequel::Migrator.apply(DB, 'migrations', target_version)
  end
end

namespace :worker do
  task :run do
    github = Github.new(login: PGQuilter::Config::GITHUB_USER,
                        password: PGQuilter::Config::GITHUB_PASSWORD)
    harness = PGQuilter::GitHarness.new
    git = PGQuilter::Git.new(harness, github)
    worker = PGQuilter::Worker.new(git)
    worker.run
  end
end
