module PGQuilter
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

    def submit_pull_request
      
    end
  end
end
