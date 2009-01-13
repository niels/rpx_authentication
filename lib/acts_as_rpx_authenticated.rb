module RpxAuthentication
  # Holds the rpxnow.com API key
  mattr_accessor :api_key
  
  # Talks to rpxnow.com to authenticate a user
  module Gateway
    # Needed to talk to rpxnow.com
    include HTTParty
    
    base_uri "rpxnow.com"
    format :json
      
    def self.authenticate(token)
      response = post(
        '/api/v2/auth_info',
        :query => {
          :apiKey => RpxAuthentication.api_key,
          :token => token,
          :extended => "true"
        }
      )
      
      return (response["stat"] == "ok") ? response["profile"] : false
    end
  end
  
end