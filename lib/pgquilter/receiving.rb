module PgQuilter
  class Receiving
    def process(msg)
      # 1. Check if any relevant attachments (attachments are going to
      #    be: text/x-diff, text/x-patch, application/x-gzip, ?)
      # 2. Find (or create) topic
      # 3. Create Patchset
      # 4. Create Patch for each attachment (unzip first if necessary)
      # 5. Schedule topic build
    end
  end
end
