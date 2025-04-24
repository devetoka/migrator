# frozen_string_literal: true

class AwsService
  def initialize
    @s3 = Aws::S3::Resource.new(
      region: 'us-east-1',
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      endpoint: ENV['AWS_ENDPOINT'], # For MinIO, use the endpoint like http://localhost:9000
      force_path_style: true         # Important for MinIO
    )
  end

  def generate_presigned_url(path)
    file_key = path
    bucket = ENV['S3_BUCKET']

    obj = @s3.bucket(bucket).object(file_key)
    presigned_url = obj.presigned_url(:put, expires_in: 3600)

    { presigned_url: presigned_url, file_key: file_key }
  end

  def download_file(file_key)
    bucket = ENV['S3_BUCKET']
    obj = @s3.bucket(bucket).object(file_key)

    raise "File not found: #{file_key}" unless obj.exists?
    obj.get.body
  end

  private

  def generate_unique_file_key
    "uploads/#{SecureRandom.uuid}.csv"
  end
end

