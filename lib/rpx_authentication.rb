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
      return (response["stat"] == "ok") ? response["profile"] : false
    end
  end
  
  # Extends the application's SessionsController with standard methods to
  # get started quickly
  module SessionsController
    def self.included(base)
      base.class_eval do
        include InstanceMethods
      end
    end
    
    module InstanceMethods
      def create
        if (params[:token] && profile = RpxAuthentication::Gateway.authenticate(params[:token]))
          unless (user = RpxAuthentication.user_model.find_by_identifier(profile["identifier"]))
            user = RpxAuthentication.user_model.create_from_rpx(profile)
          end
          
          log_user_in(user)
          login_successful
        else
          deny_access("Sorry, we couldn't log you in!")
        end
      end
    end
  end
  
  module ApplicationController
    def self.included(base)
      base.class_eval do
        include InstanceMethods
      end
    end
    
    module InstanceMethods
      def log_user_in(user)
        puts current_user.inspect
        self.current_user = user
      end
      
      def login_successful
        flash[:notice] = "You're now logged in with the identifier #{h(current_user.identifier)}"
        redirect_back
      end
      
      def deny_access(message)
        flash[:error] = message
        redirect_to(new_session_url())
      end
    end
  end
  
end

# We might constantly get reloaded in development mode.
# In this case we also need to slurp in the config after each reload (mainly to set the API key).
load "#{RAILS_ROOT}/config/initializers/rpx_authentication.rb" if RAILS_ENV == "development"