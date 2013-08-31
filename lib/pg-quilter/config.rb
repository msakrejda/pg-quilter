module PGQuilter
  module Config
    # N.B.: this must be something that is accessible when fakesu-ing
    WORK_DIR = '/app/postgres'
    UPSTREAM_REPO_URL = 'git@github.com:postgres/postgres.git'
  end
end
