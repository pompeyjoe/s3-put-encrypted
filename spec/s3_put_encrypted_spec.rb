# frozen_string_literal: true

require 'aws-sdk-kms'
require 'aws-sdk-s3'

class S3PutEncrypted
  def put
    region = 'ap-southeast-2'
    kms_key_id = '1234abcd-12ab-34cd-56ef-1234567890ab'
    target_directory = './spec/resources/dir'

    kms = Aws::KMS::Client.new(region: region)

    s3 = Aws::S3::Encryption::Client.new(
      region: region,
      kms_key_id: kms_key_id,
      kms_client: kms
    )

    Dir.glob(target_directory).each do |filename|
      if File.directory?(filename)
        puts "Skipping directory #{filename}"
        next
      end

      s3.put_object
    end
  end
end

describe S3PutEncrypted do
  let(:kms_client) { instance_double('Aws::KMS::Client') }
  let(:s3_client) { instance_double('Aws::S3::Encryption::Client') }
  let(:kms_key_id) { '1234abcd-12ab-34cd-56ef-1234567890ab' }
  let(:etag) { '6805f2cfc46c0f04559748bb039d69ae' }
  let(:region) { 'ap-southeast-2' }
  let(:target_directory) { './dir' }
  let(:put_object_response) { Aws::S3::Types::PutObjectOutput.new(etag: etag) }

  before(:each) do
    expect(Aws::KMS::Client).to receive(:new).with(region: region).and_return(kms_client)
    expect(Aws::S3::Encryption::Client).to receive(:new).with(
      region: region,
      kms_key_id: kms_key_id,
      kms_client: kms_client
    ).and_return(s3_client)
  end

  context 'when file array contains directories' do
    it 'skips directories' do
      expect(s3_client).not_to receive(:put_object)

      subject.put
    end
  end
end
