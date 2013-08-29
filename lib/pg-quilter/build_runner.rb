module PGQuilter
  class BuildRunner

    class BuildError < StandardError; end

    attr_reader :build, :harness

    def initialize(build, harness)
      @build = build
      @harness = harness
    end

    def run
      unless harness.has_workspace?
        harness.prepare_workspace
      end
      step "reset" do
        result = harness.reset build.base_rev
        [ result, { resolved_rev: harness.check_rev } ]
      end
      build.patches.sort_by(&:order).each do |patch|
        step "apply_patch" do
          result = harness.apply_patch(patch.body)
          [ result, { patch_id: patch.uuid } ]
        end
      end
      step "configure" do
        harness.configure
      end
      step "make" do
        harness.make
      end
      step "make contrib" do
        harness.make_contrib
      end
      step "make check" do
        harness.make_check
      end
      step "make contribcheck" do
        harness.make_contribcheck
      end
    rescue BuildError => e
      puts e.message
    end

    def step(name)
      start_time = Time.now
      result, attrs = yield
      build.add_build_step(step:   name,
                           started_at: start_time,
                           stdout: result.stdout,
                           stderr: result.stderr,
                           status: result.status,
                           attrs:  attrs)
      unless result.status.zero?
        raise BuildError, "Build failed on step #{name}"
      end
    end
  end
end
