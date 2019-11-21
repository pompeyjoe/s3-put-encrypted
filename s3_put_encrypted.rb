require 'optparse'
require_relative './lib/s3_putter'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: s3_put_encrypted.rb [options]"

  opts.on("-r", "--region REGION", "AWS Region") do |r|
    options[:region] = r
  end

  opts.on("-k", "--kms-key-id KMS_KEY_ID", "KMS Key ID") do |k|
    options[:kms_key_id] = k
  end

  opts.on("-b", "--bucket BUCKET", "Bucket Name") do |b|
    options[:bucket] = b
  end

  opts.on("-p", "--pattern PATTERN", "File pattern for source files") do |p|
    options[:pattern] = p
  end
end.parse!

raise OptionParser::MissingArgument.new('region') if options[:region].nil?
raise OptionParser::MissingArgument.new('kms-key-id') if options[:kms_key_id].nil?
raise OptionParser::MissingArgument.new('bucket') if options[:bucket].nil?
raise OptionParser::MissingArgument.new('pattern') if options[:pattern].nil?

putter = S3Putter.new(options)
putter.put(options[:pattern])





