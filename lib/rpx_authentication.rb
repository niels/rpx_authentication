module RpxAuthentication
  # Holds the rpxnow.com API key
  mattr_accessor :api_key, :user_model
  
  # Talks to rpxnow.com to authenticate a user
  module Gateway
    # Needed to talk to rpxnow.com
    include HTTParty
    
    base_uri "rpxnow.com"
    format :json
      
    # Authenticates and returns false or extended profile information
    def self.authenticate(token)
      response = post(
        '/api/v2/auth_info',
        :query => {
          :apiKey => RpxAuthentication.api_key,
          :token => token,
          :extended => "true"
        }
      )
      
      Rails.logger.debug("RPXnow.com says: #{response.inspect} ENDOFRPXRESPONSE")
      return response["profile"] if (response.is_a?(Hash) && response["stat"] == "ok" && response.include?("profile")) 
      false
    end
  end
end
  


# We might constantly get reloaded in development mode.
# In this case we also need to slurp in the config after each reload (mainly to set the API key).
load "#{RAILS_ROOT}/config/initializers/rpx_authentication.rb" if RAILS_ENV == "development"