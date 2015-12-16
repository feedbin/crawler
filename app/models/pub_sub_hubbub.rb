class PubSubHubbub
  def initialize(hubs, self_url, push_callback, hub_secret, subscribers)
    @hubs = hubs
    @self_url = self_url
    @push_callback = push_callback
    @hub_secret = hub_secret
    @subscribers = subscribers
  end

  def subscribe
    perform("subscribe")
  end

  def unsubscribe
    perform("unsubscribe")
  end

  private

  def perform(mode)
    @hubs.each do |hub|
      request(hub, mode)
    end
    if @hubs.empty? && ENV["PUSH_SERVICE_URL"]
      request(ENV["PUSH_SERVICE_URL"], mode, ENV["PUSH_SERVICE_USERNAME"], ENV["PUSH_SERVICE_PASSWORD"], true)
    end
  end

  def request(url, mode, username = nil, password = nil, include_subscribers = false)
    body = {}
    body['hub.mode'] = mode
    body['hub.verify'] = 'async'
    body['hub.topic'] = @self_url
    body['hub.secret'] = @hub_secret
    body['hub.callback'] = @push_callback
    body['hub.verify_token'] = @hub_secret
    body['feedbin.subscribers'] = @subscribers if include_subscribers
    Curl.post(url, body) do |http|
      if username && password
        http.http_auth_types = :basic
        http.username = username
        http.password = password
      end
    end
  end

end