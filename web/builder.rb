require 'sinatra'
require 'json'
require 'time'

class PGQuilter::Builder < Sinatra::Base

  before do
    unless request.request_method == 'OPTIONS'
      authenticate
    end
  end

  def authenticate
    auth = Rack::Auth::Basic::Request.new(request.env)
    throw(:halt, [401, "Not Authorized\n"]) unless auth.provided? && auth.basic? && auth.credentials
    token = auth.credentials.last
    unless PGQuilter::ApiToken.valid? token
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  # validate and store a build request; to be picked up by a worker
  post '/builds' do
    payload = JSON.parse request.body.read

    base_rev = payload.delete "base_rev"
    patches = payload.delete "patches"

    if base_rev.nil? || base_rev.empty? ||
        patches.nil? || patches.any? { |p| p.class != String } ||
        !payload.empty?
      status 422
    else
      build = PGQuilter::TaskMaster.create_build(base_rev, patches)
      { id: build.uuid }.to_json
    end
  end

  get '/builds' do
    PGQuilter::Build.all.map { |b| format_build(b) }.to_json
  end

  get '/builds/:uuid' do |uuid|
    b = PGQuilter::Build[uuid]
    if b.nil?
      status 404
    end
    format_build(b).to_json
  end

  get '/builds/:uuid/steps' do |uuid|
    b = PGQuilter::Build[uuid]
    if b.nil?
      status 404
    end
    b.build_steps.sort_by(&:started_at).map { |s| format_step(s) }.to_json
  end

  private

  def format_build(b)
    {
      id: b.uuid,
      created_at: format_time(b.created_at),
      state: b.state,
      patches: b.patches.sort_by(&:order).map { |p| format_patch(p) },
    }
  end

  def format_patch(p)
    { id: p.uuid, sha1: p.sha1 }
  end

  def format_step(s)
    result = {
      step: s.name,
      started_at: format_time(s.started_at),
      completed_at: format_time(s.completed_at),
      stdout: s.stdout,
      stderr: s.stderr,
      status: s.status
    }
    unless s.attrs.nil?
      result[:attrs] = s.attrs.to_hash
    end
    result
  end

  def format_time(t)
    unless t.nil?
      t.to_datetime.rfc3339
    end
  end
end
