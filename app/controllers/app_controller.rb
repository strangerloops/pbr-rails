class AppController < ApplicationController
  
  def home
    render json: { time: Time.now }
  end

  def route

    city = params[:city]
    origin = params[:origin]
    destination = params[:destination]
    
    if city && origin && destination
      render json: route_for(origin: origin, destination: destination, city: city)
    else
      render json: { error: 'you are missing some parameters, my friend.' }
    end
  end

  def route_for(origin:, destination:, city:)
    results = []
    start  = geocode origin
    finish = geocode destination
    endpoints[city].each do |endpoint|
      url = endpoint[:address] + "route/v1/bike/#{start['lng']},#{start['lat']};#{finish['lng']},#{finish['lat']}"
      response = get_url(url)
      if response.code == '200'
        body = JSON.parse(response.body)
        body[:profile_name] = endpoint[:profile_name]
        encoded_polyline = body['routes'].first['geometry']
        decoded_polyline = ::Polylines::Decoder.decode_polyline(encoded_polyline)
        midpoint = decoded_polyline[decoded_polyline.count / 2]
        body[:midpoint] = midpoint
        results.push(body)
      else
        raise 'Could not get route.'
      end
    end
    results
  end

  def geocode(address)
    key = 'AIzaSyA1Cy1OtiZATWJvY4B251DkqmYR42L27TE'
    url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{address}&#{key}"
    response = get_url(url)
    if response.code == '200'
      body = JSON.parse(response.body)
      results = body['results']
      result = results.first
      geometry = result['geometry']
      geometry['location']
    else
      raise 'Could not geocode.'
    end
  end

  def endpoints
    {
      # 'chi' => [ { address: 'http://54.186.10.196:5000/',  profile_name: 'cautious' },
      #            { address: 'http://54.187.224.112:5000/', profile_name: 'comfortable' },
      #            { address: 'http://54.200.130.188:5000/', profile_name: 'direct' } ],
      'nyc' => [
                { address: 'http://52.25.196.129:2345/',   profile_name: 'comfortable' },
                { address: 'http://52.25.196.129:1234/',   profile_name: 'direct' },
                # { address: 'http://54.187.200.153:5000/', profile_name: 'direct' }
               ]
                  
    }
  end

  def get_url(url_string)
    Net::HTTP.get_response(URI.parse(URI.encode(url_string)))
  end
end
