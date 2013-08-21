require 'sinatra'
require 'json'
require 'mail'

class PGQuilter::Builder < Sinatra::Base
  # validate and store a build request; to be picked up by a worker
  post '/build' do
    payload = JSON.parse request.body.read

    base_sha = payload.delete "base_sha"
    patches = payload.delete "patches"

    if base_sha.nil? || base_sha.empty? ||
        patches.nil? || patches.any? { |p| p.class != String } ||
        !payload.empty?
      status 422
    else
      PGQuilter::TaskMaster.create_build(base_sha, patches)
      200
    end
  end
end
