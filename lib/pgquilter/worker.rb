module PgQuilter
  class Worker

    WORKSPACE_DIR = 'postgres'

    def run
      prepare_workspace

      FileUtils.cd(WORKSPACE_DIR) do
        if apply_patchset
          push_to_github
          submit_pull_request
        end
      end
    end

    private
    def run_cmd(cmd)
      stdout, stderr
    end

    def prepare_workspace
      unless File.directory? WORKSPACE_DIR
        # clone postgres repo
      end

      # check out master branch

      run_cmd "git checkout master"
      run_cmd "git reset --hard origin/master"
      run_cmd "git show-ref -s refs/heads/master"
    end

    def apply_patchset
      patchset.patches.sort_by { |patch| patch.patchset_order }.each do |patch|
        patch_name = "#{patchset.topic.name}-#{patchset.message_id}-#{patch.patchset_order}.patch"
        run_cmd("curl patch.patch_url > #{patch_name}")
        run_cmd("git apply #{patch_name}")
      end
    end

    def push_to_github
      
    end

    def submit_pull_request
      
    end
  end
end
