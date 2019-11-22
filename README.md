# S3 Put Encrypted

s3-put-encrypted is a Ruby utility for putting objects to S3 using [Client-Side Encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html)

## Pre-requisites

1. AWS Account containing:
   1. an S3 bucket
   2. a KMS [customer master key (CMK)](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys) to be used for client-side encryption
   3. an IAM user with:
      * "s3:GetObject" and "s3:PutObject" permissions for the above S3 bucket
      * "kms:GenerateDataKey" permission for the above KMS CMK
   
2. Ruby 2.4.1, with [bundler gem](https://bundler.io/), installed

#### Generate KMS CMK

With a user that has the "kms:CreateKey" permission, run the following

```bash
AWS_ACCESS_KEY_ID=your_access_key_id AWS_SECRET_ACCESS_KEY=your_secret_access_key aws kms create-key --region <region>
```

See [here](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/setup-config.html#aws-ruby-sdk-credentials-environment) for 
alternative ways to configure AWS Credentials

## Usage

One time installation of bundler and required Ruby gems
```bash
gem install bundler
bundle install
```

Put local files that match the provided 'pattern' to given S3 bucket, encrypted client-side using the KMS CMK with the specified key ID
```bash
AWS_ACCESS_KEY_ID=your_access_key_id AWS_SECRET_ACCESS_KEY=your_secret_access_key \ 
  ruby s3_put_encrypted.rb \
    -r us-west-2 \
    -k 1234abcd-12ab-34cd-56ef-1234567890ab \
    -b my-bucket \
    -p './foo/bar/**/*'
```

Option | Description
--- | ---
-r / --region | The AWS region in which the KMS key and S3 bucket reside |
-k / --kms-key-id | The key ID of the customer master key (CMK) that will be used for client-side encryption |
-b / --bucket | The S3 bucket name | |
-p / --pattern | The [Ruby](https://ruby-doc.org/core-2.4.1/Dir.html#method-c-glob) file matching pattern for selecting local files to be put to S3 |

See [here](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/setup-config.html#aws-ruby-sdk-credentials-environment) for 
alternative ways to configure AWS Credentials


