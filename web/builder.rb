require 'sinatra'
require 'json'
require 'mail'

class PGQuilter::Builder < Sinatra::Base
  # validate and store a build request; to be picked up by a worker
  post '/builds' do
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

  get '/builds/:uuid' do |uuid|
    b = PGQuilter::Build[uuid]
    if b.nil?
      status 404
    end
    {
      id: uuid,
      created_at: b.created_at,
      patches: b.patches.sort_by(&:order).map do |p|
        {
          sha1: Digest::SHA1.hexdigest(p.body)
        }
      end,
      status: 'pending'
    }.to_json
  end
end
