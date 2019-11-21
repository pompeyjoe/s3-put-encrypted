require 'aws-sdk-kms'
require 'aws-sdk-s3'

class S3Adapter
  def initialize(options = {})
    kms = Aws::KMS::Client.new(region: options[:region])

    @s3 = Aws::S3::Encryption::Client.new(
      region: options[:region],
      kms_key_id: options[:kms_key_id],
      kms_client: kms
    )
  end

  def object_exists?(bucket, key)
    object = @s3.head_object(
      bucket: bucket,
      key: key
    )
    true
  rescue Aws::S3::Errors::NotFound
    false
  end

  def put_object(options = {})
    @s3.put_object(options)
  end
end