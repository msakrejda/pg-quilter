module PgQuilter
  class Receiving
    def process(msg)
      # 1. Check if message is a topic message
      # 2. Find (or create) topic
      # 3. Create patchset
      # 4. For each attachment
      #    a) download
      #    b) unzip if necessary
      #    c) create patch
      # 5. Schedule patchset build
    end
  end
end
