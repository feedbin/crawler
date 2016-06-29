class Upload
  S3_POOL = ConnectionPool.new(size: 10, timeout: 5) do
    Fog::Storage.new(
      provider: "AWS",
      aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      persistent: true
    )
  end

  def initialize(file_path)
    @file_path = file_path
  end

  def upload
    S3_POOL.with do |connection|
      File.open(@file_path) do |file|
        @response = connection.put_object(ENV['AWS_S3_BUCKET'], path, file, options)
      end
    end
    url
  end

  private

  def url
    if @response
      URI::HTTP.build(
        scheme: 'https',
        host: @response.data[:host],
        path: @response.data[:path]
      ).to_s
    end
  end

  def path
    @path ||= File.join("public-images", "#{SecureRandom.hex(1)}-#{Time.now.utc.strftime("%F")}", File.basename(@file_path))
  end

  def options
    {
      "Cache-Control" => "max-age=315360000, public",
      "Expires" => "Sun, 29 Jun 2036 17:48:34 GMT",
      "x-amz-storage-class" => "REDUCED_REDUNDANCY"
    }
  end

end