module PgQuilter
  module Receiving
    extend self

    # TODO: also support compressed patches like application/x-gzip
    PATCH_TYPES = %w(text/x-diff, text/x-patch)

    def handle(message)
      puts "You've got mail!"
      log message
      if of_interest? message
        process message
      end
    end

    def process(message)
      puts "Processing message"
      message['attachments'].each do |k, attachment|
        puts attachment.class
        puts attachment
        puts attachment[:type]

        content = attachment[:tempfile].read

        puts content
      end
      # 1. Check if any relevant attachments
      # 2. Find (or create) topic
      # 3. Create Patchset
      # 4. Create Patch for each attachment (unzip first if necessary)
      # 5. Schedule topic build
      # do something with mail
    end

    def of_interest?(message)
      message && is_to_hackers?(message) && includes_patches?(message)
    end

    def is_to_hackers?(message)
      list = message['headers']['X-Mailing-List']
      list == PGQuilter::Config::PGSQL_HACKERS
    end

    def includes_patches?(message)
      message.has_key?('attachments') &&
        !(PATCH_TYPES & message.attachments.map { |a| a[:type] }).empty?
    end

    def log(message)
      headers = message['headers']

      puts "Received message"
      puts "To: #{headers['To']}"
      puts "From: #{headers['From']}"
      puts "Date: #{headers['Date']}"
      puts "Subject: #{headers['Subject']}"
      puts "Body:\n#{message['plain']}"
    end
  end
end
