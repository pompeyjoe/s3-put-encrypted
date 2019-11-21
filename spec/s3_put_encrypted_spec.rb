# frozen_string_literal: true

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

class S3PutEncrypted
  def put(options = {})
    region = 'ap-southeast-2'
    kms_key_id = '1234abcd-12ab-34cd-56ef-1234567890ab'

    s3 = S3Adapter.new(
      region: region,
      kms_key_id: kms_key_id
    )

    Dir.glob(options[:file_pattern]).each do |filename|
      if File.directory?(filename)
        puts "Skipping directory #{filename}"
        next
      end

      ctime = File.ctime(filename)
      basename = File.basename(filename)
      key = ctime.strftime("%Y/%m/%Y-%m-%d-#{basename}")

      if s3.object_exists?(options[:bucket], key)
        puts "Skipping existing file: #{filename}"
        next
      end

      s3.put_object(
        bucket: options[:bucket],
        key: key,
        body: File.read(filename)
      )
    end
  end
end

describe S3PutEncrypted do
  let(:kms_client) { instance_double('Aws::KMS::Client') }
  let(:s3_client) { instance_double('Aws::S3::Encryption::Client') }
  let(:kms_key_id) { '1234abcd-12ab-34cd-56ef-1234567890ab' }
  let(:etag) { '6805f2cfc46c0f04559748bb039d69ae' }
  let(:region) { 'ap-southeast-2' }
  let(:bucket) { 'my-bucket' }
  let(:put_object_response) { Aws::S3::Types::PutObjectOutput.new(etag: etag) }
  let(:put_options) do
    {
      bucket: bucket,
      file_pattern: file_pattern
    }
  end

  before(:each) do
    expect(Aws::KMS::Client).to receive(:new).with(region: region).and_return(kms_client)
    expect(Aws::S3::Encryption::Client).to receive(:new).with(
      region: region,
      kms_key_id: kms_key_id,
      kms_client: kms_client
    ).and_return(s3_client)
  end

  context 'when file pattern matches directory' do
    let(:file_pattern) { './spec/resources/dir' }
    it 'skips put' do
      expect(s3_client).not_to receive(:put_object)

      subject.put(put_options)
    end
  end

  context 'when file pattern matches files' do
    let(:file_pattern) { './spec/resources/files/**/*' }
    it 'puts files to S3' do
      a = File.read('./spec/resources/files/a.txt')
      b = File.read('./spec/resources/files/sub/b.txt')

      expect(s3_client).to receive(:head_object).with(
        bucket: bucket,
        key: '2019/11/2019-11-21-a.txt'
      ).and_raise(Aws::S3::Errors::NotFound.new({}, 'dummy'))

      expect(s3_client).to receive(:put_object).with(
        bucket: bucket,
        key: '2019/11/2019-11-21-a.txt',
        body: a
      ).and_return(put_object_response)

      expect(s3_client).to receive(:head_object).with(
        bucket: bucket,
        key: '2019/11/2019-11-21-b.txt'
      ).and_raise(Aws::S3::Errors::NotFound.new({}, 'dummy'))

      expect(s3_client).to receive(:put_object).with(
        bucket: bucket,
        key: '2019/11/2019-11-21-b.txt',
        body: b
      ).and_return(put_object_response)

      subject.put(put_options)
    end
  end

  context 'when file already exists' do
    let(:file_pattern) { './spec/resources/files/a.txt' }
    it 'skips put' do

      expect(s3_client).to receive(:head_object).with(bucket: bucket, key: '2019/11/2019-11-21-a.txt').and_return(Aws::S3::Types::HeadObjectOutput.new)
      expect(s3_client).not_to receive(:put_object)

      subject.put(put_options)
    end
  end
end
