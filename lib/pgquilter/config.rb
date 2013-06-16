module PGQuilter
  module Config
    LOG_LEVEL = ENV['LOG_LEVEL']

    QUILTER_NAME = 'pg-quilter'
    QUILTER_EMAIL = ENV['QUILTER_EMAIL']

    GITHUB_USER = 'pg-quilter'
    GITHUB_PASSWORD = ENV['GITHUB_PASSWORD']

    PGSQL_HACKERS = 'pgsql-hackers'

    WORK_DIR = '/tmp/postgres'
    WORK_REPO_URL = 'git@github.com:pg-quilter/postgres.git'
    CANONICAL_REPO_URL = 'git@github.com:postgres/postgres.git'
  end
end
