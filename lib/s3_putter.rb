# frozen_string_literal: true

require_relative 's3_adapter'
require_relative 'key_generator'

# Puts local files that match the provided 'pattern' to given S3 bucket,
# encrypted client-side using the KMS CMK with the specified key ID
class S3Putter
  def initialize(options = {})
    @s3 = S3Adapter.new(
      region: options[:region],
      kms_key_id: options[:kms_key_id]
    )

    @bucket = options[:bucket]
  end

  def put(file_pattern)
    puts "Putting files matching #{file_pattern}..."

    Dir.glob(file_pattern).each { |f| put_file(f) }

    puts 'Done!'
  end

  private

  def put_file(filename)
    if File.directory?(filename)
      puts "Skipping directory #{filename}"
      return
    end

    key = KeyGenerator.generate(filename)

    if @s3.object_exists?(@bucket, key)
      puts "Skipping existing file: #{filename}"
      return
    end

    puts "Putting #{filename}..."

    resp = @s3.put_object(
      bucket: @bucket,
      key: key,
      body: File.read(filename)
    )

    puts "Put #{filename}! etag: '#{resp.etag}'"
  end
end
