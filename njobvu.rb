require 'sinatra'
require 'json'
require 'mail'

# Ensure we see logs
$stdout.sync = true

post '/mail' do
  mail = Mail.new(params[:message])
  # do something with mail
  puts "Got an e-mail!"
  puts "Sender: #{mail.sender}"
  puts "Subject: #{mail.subject}"
  puts "Date: #{mail.date.to_s}"
  puts "Body: #{mail.body.decoded}"
end
