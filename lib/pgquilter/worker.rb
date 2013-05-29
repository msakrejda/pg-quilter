module PGQuilter
  class Worker

    WORKSPACE_DIR = 'postgres'

    def run
      prepare_workspace
      if apply_patchset
        submit_pull_request
        push_to_github
        # if no pull request exists, create one
      end
    end

    def submit_pull_request
      
    end
  end
end
