class Upload
  def initialize(file_path)
    @file_path = file_path
  end

  def upload
    S3_POOL.with do |connection|
      File.open(@file_path) do |file|
        response = connection.put_object(ENV['AWS_S3_BUCKET'], path, file, options)
        build_url(response)
      end
    end
  end

  private

  def build_url(response)
    URI::HTTPS.build(
      host: response.data[:host],
      path: response.data[:path]
    ).to_s
  end

  def path
    @path ||= begin
      basename = File.basename(@file_path)
      File.join(basename[0..6], basename)
    end
  end

  def options
    {
      "Cache-Control" => "max-age=315360000, public",
      "Expires" => "Sun, 29 Jun 2036 17:48:34 GMT",
      "x-amz-storage-class" => "REDUCED_REDUNDANCY"
    }
  end

end