# frozen_string_literal: true

require 'securerandom'
require_relative '../lib/s3_putter'

describe S3Putter do
  let(:kms_client) { instance_double('Aws::KMS::Client') }
  let(:s3_client) { instance_double('Aws::S3::Encryption::Client') }
  let(:kms_key_id) { '1234abcd-12ab-34cd-56ef-1234567890ab' }
  let(:etag) { SecureRandom.hex }
  let(:region) { 'ap-southeast-2' }
  let(:bucket) { 'my-bucket' }
  let(:put_object_response) { Aws::S3::Types::PutObjectOutput.new(etag: etag) }
  let(:options) do
    {
      region: region,
      kms_key_id: kms_key_id,
      bucket: bucket
    }
  end

  subject do
    S3Putter.new(options)
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

      subject.put(file_pattern)
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

      subject.put(file_pattern)
    end
  end

  context 'when file already exists' do
    let(:file_pattern) { './spec/resources/files/a.txt' }
    it 'skips put' do

      expect(s3_client).to receive(:head_object).with(bucket: bucket, key: '2019/11/2019-11-21-a.txt').and_return(Aws::S3::Types::HeadObjectOutput.new)
      expect(s3_client).not_to receive(:put_object)

      subject.put(file_pattern)
    end
  end
end
