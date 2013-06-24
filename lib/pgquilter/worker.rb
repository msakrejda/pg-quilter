module PGQuilter
  class Worker
    include Loggable

    WORKER_FREQUENCY = 60 * 60 # once an hour

    def initialize(git)
      @git = git
    end

    def run_builds(for_sha)
      # N.B.: the builds will not necessarily be against this base
      # SHA--there's an inherent race condition and new commits may be
      # mande in the meantime. That's fine--the underlying
      # infrastructure records the correct SHA, and this only gives us
      # an indication of whether we need to rebuild at all.

      # TODO: avoid rebuilding if the topic build previously failed
      # and upstream has progressed but there are no new patchsets:
      # this situation is unlikely to have fixed anything with the
      # patch
      candidates = Topic.active.without_build(for_sha)

      unless candidates.empty?
        log "Starting builds for #{candidates.count} candidates"
        candidates.select { |topic| @git.pull_request_active? topic }.each do |topic|
          run_build(topic)
        end
        log "Completed #{candidates.count} builds"
      end
    end

    # Run build for given topic against current git HEAD
    def run_build(topic)
      # N.B. We only care about rebuilding the latest patchset
      patchset = topic.patchsets_dataset.order_by(:created_at).last

      @git.apply_patchset(patchset)
      @git.update_pull_request(patchset)
    rescue StandardError => e
      log "Could not complete build: #{e.message}"
      raise
    end

    def run
      last_sha = nil
      loop do
        t0 = Time.now
        sha = @git.check_upstream_sha
        if sha != last_sha
          run_builds(sha)
          last_sha = sha
        end
        t1 = Time.now
        duration = t1 - t0
        if duration < WORKER_FREQUENCY
          sleep(WORKER_FREQUENCY - duration)
        end
      end
    end

  end
end
