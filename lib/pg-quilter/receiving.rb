require 'pp'
require 'logger'

module PGQuilter
  module Receiving
    include Loggable
    extend self

    class Failure < Sequel::Model; end

    def handle(message)
      return unless message

      log "You've got mail!"
      log_message message
      if of_interest? message
        process message
      end
    end

    def process(message)
      log "Processing message"

      subject = message['headers']['Subject']
      topic = Topic.for_subject(subject)

      author =  message['headers']['From']
      message_id = message['headers']['Message-ID'].gsub!(/^<|>$/,'')
      patchset = topic.add_patchset(author: author, message_id: message_id)

      begin
        patch_no = 0
        message['attachments'].sort_by { |k, v| k.to_i }.select do |k, attachment|
          is_patch?(attachment)
        end.each do |k, attachment|
          filename = attachment[:filename]
          content = get_patch_content(attachment)
          patchset.add_patch(patchset_order: patch_no, filename: filename, body: content)
          patch_no += 1
        end
      rescue StandardError => e
        Failure.create(message_id: message_id, error: e.message)
      end
    end

    def of_interest?(message)
      message && is_to_hackers?(message) && includes_patches?(message)
    end

    def is_to_hackers?(message)
      list = message['headers']['X-Mailing-List']
      to_hackers = list == ::PGQuilter::Config::PGSQL_HACKERS
      log "to hackers?: #{to_hackers}"
      to_hackers
    end

    def is_patch?(attachment)
      mime_type = attachment[:type]

      definitely_patch = %w(text/x-diff text/x-patch).include? mime_type
      maybe_patch = %w(text/x-plain application/octet-stream).include? mime_type
      filename = attachment[:filename]

      is_patch = definitely_patch || (maybe_patch && filename =~ /\.(?:patch|diff)\z/)
      log "\tattachment #{filename} (type #{mime_type}) is patch: #{is_patch}"
      is_patch
    end

    def get_patch_content(attachment)
      # TODO: also support compressed patches like application/x-gzip;
      # this will also need tweaks to is_patch? above
      attachment[:tempfile].read
    end

    def includes_patches?(message)
      attachments = message['attachments'] || []
      patches = attachments.select do |index, attachment|
        is_patch?(attachment)
      end
      log "has #{attachments.count} attachment(s); #{patches.count} patch(es)"
      attachments.each do |n, a|
        log "\tattachment #{n}: #{a[:type]}  #{a[:filename]}"
      end
      !patches.empty?
    end

    def log_message(message)
      log "Dumping message:"
      log message.pretty_inspect

      headers = message['headers']

      if headers
        log "Received message"
        log "To: #{headers['To']}"
        log "From: #{headers['From']}"
        log "Date: #{headers['Date']}"
        log "Subject: #{headers['Subject']}"
        log "Body:\n#{message['plain']}"
      end
    end
  end
end
