class TheTvDbApi
  BASE_URL = 'https://api.thetvdb.com'

  ## Authentication Methods
  def self.request_token
    response = connection.post do |req|
      req.url '/login'
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'

      req.body = {
          apikey: ENV['TV_DB_API_KEY'],
          username: ENV['TV_DB_USER_NAME'],
          userkey: ENV['TV_DB_USER_KEY']
        }.to_json
    end

    jwt_token = JSON::parse(response.body)['token']
    JwtToken.create(
        token: jwt_token,
        expiration_date: 23.hours.from_now
      )
  end

  def self.refresh_token
    get_response '/refresh_token'
    JwtToken.last.update_attribute(
        expiration_date: 23.hours.from_now
      )
  end

  ## Search for a particular series
  def self.search query
    url = "search/series?name=#{URI.encode query}"
    series = get_response url
  end

  ## Others
  def self.update_series
    from_date = 65.minutes.ago.to_i
    url = "/updated/query?fromTime=#{from_date}"
    series = get_response url

    series.each do |serie|
      serie_info = get_serie serie['id']
    end
  end

  def self.get_serie serie_id
    response = get_response "/series/#{serie_id}"
  end

  def self.get_serie_actors serie_id
    response = get_response "/series/#{serie_id}/actors"
  end

  def self.get_serie_fanart serie_id
    url = "series/#{serie_id}/images/query?keyType=poster"
    response = get_response url
  end

  private
  def self.connection
    Faraday.new(url: BASE_URL) do |faraday|
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end
  end

  def self.get_response url
    token = JwtToken.last.token
    response = connection.get do |req|
      req.url url
      req.headers['Accept'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{token}"
    end
    JSON::parse(response.body)['data']
  end
end