module PGQuilter
  class Worker

    def initialize(harness)
      @harness = harness
    end

    # Run given build
    def run_build(build)
      runner = BuildRunner.new(build, @harness)
      puts "Starting build #{build.uuid}"
      runner.run
    rescue StandardError => e
      puts "Could not complete build #{build.uuid}: #{e.message}"
    ensure
      puts "Build #{build.uuid} finished"
    end

    # Run unbuilt builds
    def run
      loop do
        Build.with_first_unbuilt do |candidate|
          run_build candidate
        end
        sleep 5
      end
    end

  end
end
