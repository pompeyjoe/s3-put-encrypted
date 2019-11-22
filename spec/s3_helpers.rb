module S3Helpers
  def not_found_error
    Aws::S3::Errors::NotFound.new({}, 'dummy')
  end
end