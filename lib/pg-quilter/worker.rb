module PGQuilter
  class Worker

    WORKER_FREQUENCY = 60 * 60 # once an hour

    def initialize(git)
      @git = git
    end

    def check_builds(last_sha)
      sha = @git.check_upstream_sha
      if sha != last_sha
        run_builds(sha)
      end
      sha
    end

    def run_builds(for_sha)
      # N.B.: the builds will not necessarily be against this base
      # SHA--there's an inherent race condition and new commits may be
      # mande in the meantime. That's fine--the underlying
      # infrastructure records the correct SHA, and this only gives us
      # an indication of whether we need to rebuild at all.
      candidates = Topic.active.without_build(for_sha).all

      unless candidates.empty?
        puts "Starting builds for #{candidates.count} candidates"
        candidates.each { |topic| check_topic(topic) }
        puts "Completed #{candidates.count} builds"
      end
    end

    def check_topic(topic)
      if @git.pull_request_active? topic
        latest_patchset = topic.latest_patchset
        # Avoid rebuilding if the topic build previously failed
        # and upstream has progressed but there are no new
        # patchsets: this situation is unlikely to have fixed
        # anything with the patches
        unless latest_patchset.last_build_failed?
          run_build(topic)
        end
      else
        topic.active = false
        topic.save_changes
      end
    end

    # Run build for given patchset against current git HEAD
    def run_build(topic)
      @git.apply_patchset(topic.latest_patchset)
      @git.push_to_github(topic)
      @git.ensure_pull_request(topic)
    rescue StandardError => e
      puts "Could not complete build: #{e.message}"
      raise
    end

    def run
      # N.B.: this may be somewhat inaccurate, as theoretically, we
      # could have some builds off a newer base_sha. Close enough for
      # now.
      last_sha = PGQuilter::Application.last_sha
      loop do
        t0 = Time.now
        last_sha = check_builds(last_sha)
        t1 = Time.now
        duration = t1 - t0
        if duration < WORKER_FREQUENCY
          sleep(WORKER_FREQUENCY - duration)
        end
      end
    end

  end
end
