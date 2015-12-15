class PubSubHubbub
  def initialize(hubs, self_url, push_callback, hub_secret, subscribers)
    @hubs = hubs
    @self_url = self_url
    @push_callback = push_callback
    @hub_secret = hub_secret
    @subscribers = subscribers
  end

  def subscribe
    @hubs.each do |hub|
      request(url)
    end
    if @hubs.empty? && ENV["PUSH_SERVICE_URL"]
      request(ENV["PUSH_SERVICE_URL"], ENV["PUSH_SERVICE_USERNAME"], ENV["PUSH_SERVICE_PASSWORD"], true)
    end
  end

  def request(url, username = nil, password = nil, include_subscribers = false)
    body = {}
    body['hub.mode'] = 'subscribe'
    body['hub.verify'] = 'async'
    body['hub.topic'] = @self_url
    body['hub.secret'] = @hub_secret
    body['hub.callback'] = @push_callback
    if include_subscribers
      body['feedbin.subscribers'] = @subscribers
    end

    Curl.post(url, body) do |http|
      if username && password
        http.http_auth_types = :basic
        http.username = username
        http.password = password
      end
    end
  end

end