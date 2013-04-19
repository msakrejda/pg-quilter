module PgQuilter
  class Receiving
    def self.process(message)
      puts "You've got mail!"
      return unless message.has_key? 'attachments'

      headers = message['headers']

      puts "From: #{headers['From']}"
      puts "Date: #{headers['Date']}"
      puts "Subject: #{headers['Subject']}"

      message['attachments'].each do |k, attachment|
        puts attachment.class
        puts attachment
        puts attachment[:type]

        content = attachment[:tempfile].read

        puts content
      end
      # 1. Check if any relevant attachments (attachments are going to
      #    be: text/x-diff, text/x-patch, application/x-gzip, ?)
      # 2. Find (or create) topic
      # 3. Create Patchset
      # 4. Create Patch for each attachment (unzip first if necessary)
      # 5. Schedule topic build
      # do something with mail
    end
  end
end
