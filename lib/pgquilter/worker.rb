module PGQuilter
  class Worker
    include Loggable

    WORKER_FREQUENCY = 60 * 60 # once an hour

    def run_builds(for_sha)
      # N.B.: the builds will not necessarily be against this base
      # SHA--there's an inherent race condition and new commits may be
      # mande in the meantime. That's fine--the underlying
      # infrastructure records the correct SHA, and this only gives us
      # an indication of whether we need to rebuild at all.
      candidates = Topic.active.without_build(for_sha)

      log "Starting builds for #{candidates.count} topics"
      candidates.each do |topic|
        run_build(topic)
      end
      log "Completed #{candidates.count} builds"
    end

    # Run build for given topic against current git HEAD
    def run_build(topic)
      harness = PGQuilter::GitHarness.new
      git = PGQuilter::Git.new(harness)

      patchset = topic.patchsets_dataset.order_by(:created_at).last

      git.apply_patchset(patchset)
      git.update_pull_request(patchset)
    rescue StandardError => e
      log "Could not complete build: #{e.message}"
      raise
    end

    def run
      last_sha = nil
      loop do
        t0 = Time.now
        sha = GitHarness.check_upstream_sha
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
