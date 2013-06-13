require 'pp'

module PGQuilter
  module Receiving
    extend self

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

      message['attachments'].sort_by { |k, v| k.to_i }.select do |k, attachment|
        is_patch?(attachment)
      end.each do |k, attachment|
        filename = attachment[:filename]
        content = get_patch_content(attachment)

        patchset.add_patch(patchset_order: k.to_i, filename: filename, body: content)
      end
    end

    def of_interest?(message)
      message && is_to_hackers?(message) && includes_patches?(message)
    end

    def is_to_hackers?(message)
      list = message['headers']['X-Mailing-List']
      to_hackers = list == PGQuilter::Config::PGSQL_HACKERS
      puts "to hackers?: #{to_hackers}"
      to_hackers
    end

    def is_patch?(attachment)
      mime_type = attachment[:type]

      definitely_patch = %w(text/x-diff, text/x-patch).include? mime_type
      maybe_patch = %w(text/plain, application/octet-stream).include? mime_type

      filename = attachment[:filename]

      is_patch = definitely_patch || maybe_patch && filename =~ /\.(?:patch|diff)\z/
      puts "\tattachment #{filename} (type #{type}) is patch: #{is_patch}"
      is_patch
    end

    def get_patch_content(attachment)
      # TODO: also support compressed patches like application/x-gzip;
      # this will also need tweaks to is_patch? above
      attachment[:tempfile].read
    end

    def includes_patches?(message)
      has_attachments = message.has_key?('attachments')
      patches = if has_attachments
                  message['attachments'].select do |index, attachment|
                    is_patch?(attachment)
                  end
                else
                  []
                end

      puts "has attachments: #{has_attachments} (#{patches.count} patches)"
      if has_attachments
        message['attachments'].each do |n, a|
          puts "\tattachment #{n}: #{a[:type]}  #{a[:filename]}"
        end
      end

      has_attachments && patches.count > 0
    end

    def log(message)
      puts "Dumping message:"
      pp message

      headers = message['headers']

      if headers

        puts "Received message"
        puts "To: #{headers['To']}"
        puts "From: #{headers['From']}"
        puts "Date: #{headers['Date']}"
        puts "Subject: #{headers['Subject']}"
        puts "Body:\n#{message['plain']}"
      end
    end
  end
end
