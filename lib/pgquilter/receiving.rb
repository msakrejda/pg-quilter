module PgQuilter
  class Receiving
    class FormatError < StandardError; end

    def self.process(mail)
      unless mail.multipart?
        raise FormatError, "Expected multipart mail"
      end

      puts "You've got mail!"

        
      puts "From: #{mail.envelope.from}"
      puts "Or maybe from: #{mail.from.addresses.join}"
      puts "Or maybe: #{mail.sender.address}"
      puts "Sent to: #{mail.to}"
      puts "CC: #{mail.cc}"
      puts "Subject: #{mail.subject}"
      Puts "Sent: #{mail.date.to_s}"

      mail.attachments.each do |attachment|
        puts "File name: #{attachment.filename}"
        puts "Content type: #{attachment.content_type}"
        puts "Body: #{attachment.body.decoded[0-250]}"
      end
      # 1. Check if any relevant attachments (attachments are going to
      #    be: text/x-diff, text/x-patch, application/x-gzip, ?)
      # 2. Find (or create) topic
      # 3. Create Patchset
      # 4. Create Patch for each attachment (unzip first if necessary)
      # 5. Schedule topic build
      # do something with mail
      puts "Got an e-mail!"
      puts "Sender: #{mail.sender}"
      puts "Subject: #{mail.subject}"
      puts "Date: #{mail.date.to_s}"
      puts "Body: #{mail.body.decoded}"
    end
  end
end
