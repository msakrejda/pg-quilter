require 'sinatra'
require 'json'
require 'mail'

class PGQuilter::Builder < Sinatra::Base
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
      PGQuilter::TaskMaster.create_build(base_rev, patches)
      200
    end
  end

  get '/builds' do
    PGQuilter::Build.all.map { |b| format_build(b) }
  end

  get '/builds/:uuid' do |uuid|
    b = PGQuilter::Build[uuid]
    if b.nil?
      status 404
    end
    format_build(b)
  end

  get '/builds/:uuid/status' do |uuid|
    b = PGQuilter::Build[uuid]
    if b.nil?
      status 404
    end
    {
      build_id: b.uuid,
      steps: b.build_steps.order_by(&:started_at).map do |s|
        {
          step: s.step,
          started_at: s.started_at,
          completed_at: s.completed_at,
          stdout: s.stdout,
          stderr: s.stderr,
          status: s.status,
          attrs:  s.attrs
        }
      end
    }
  end

  private

  def format_build(b)
    {
      id: b.uuid,
      created_at: b.created_at,
      patches: b.patches.sort_by(&:order).map { |p| format_patch(p) },
    }.to_json
  end

  def format_patch(p)
    { id: p.uuid, sha1: p.sha1 }
  end
end
