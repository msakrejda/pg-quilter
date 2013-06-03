module PGQuilter
  class Worker

    def schedule_builds
      sha = Git.check_upstream_sha
      candidates = Topic.active.without_build(sha)
      # schedule builds for all candidates
    end

    def run(uuid)
      loop do
        patchset = Patchset[uuid]
        if patchset.nil?
          raise StandardError, "Could not find patchset #{uuid}"
        end
        # TODO: break out Git into high-level interface we interact
        # with here and lower-level interface to the underlying tools
        g = Git.new
        g.submit_patchset patchset
      end
    end

    def build_patchset
      
    end
  end
end
