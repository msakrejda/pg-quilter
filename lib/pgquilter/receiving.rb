module PgQuilter
  module Receiving
    extend self

    # TODO: also support compressed patches like application/x-gzip
    PATCH_TYPES = %w(text/x-diff, text/x-patch)

    def handle(message)
      return unless message

      puts "You've got mail!"
      log message
      if of_interest? message
        process message
      end
    end

    def process(message)
      puts "Processing message"

      subject = message['headers']['Subject']
      topic = Topic.for_subject(subject)

      author =  message['headers']['From']
      message_id = message['headers']['Message-ID'].gsub!(/^<|>$/,'')
      patchset = topic.add_patchset(author: author, message_id: message_id)

      message['attachments'].sort.select do |k, attachment|
        PATCH_TYPES.include? attachment[:type]
      end.each do |k, attachment|
        filename = attachment[:filename]
        content = attachment[:tempfile].read

        patchset.add_patch(patchset_order: k.to_i, filename: filename, body: content)
      end
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
        !(PATCH_TYPES & message['attachments'].map { |a| a[:type] }).empty?
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
