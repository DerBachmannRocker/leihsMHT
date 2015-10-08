require 'optparse'

class Mailer < ActionMailer::Base
  def message(recipients, subject, body)
      mail(to: recipients,
           subject: subject,
           body: body)
  end

end

options = OpenStruct.new
options.recipients = ''
options.subject = 'No subject'
options.body = 'No message.'

OptionParser.new do |opts|
  opts.banner = 'Usage: rails runner mail.rb [options]'

  opts.on('-r', '--recipients RECIPIENTS', Array, 'The recipients of the email, comma-separated, no spaces') do |r|
    options.recipients = r
  end

  opts.on('-s', '--subject [SUBJECT]', 'The subject of the email') do |s|
    options.subject = s
  end

  opts.on('-b', '--body [BODY]', 'The body of the email') do |b|
    options.body = b
  end

end.parse!

message = Mailer.message(options.recipients, options.subject, options.body)
# Why would this raise such an error: *** wrong number of arguments (0 for 3)
# when clearly 3 of 3 arguments are defined?
message.deliver_now

p options
p ARGV
