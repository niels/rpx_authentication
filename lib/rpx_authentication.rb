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
  
  module UserModel
    def self.included(base)
      base.class_eval do
        cattr_accessor :rpx_mappings
        self.rpx_mappings = {
          :avatar => :photo,
          :given_name => "name:givenName",
          :family_name => "name:familyName",
          :username => [:preferredUsername, :displayName],
          :identifier => :identifier,
          :email => [:verified_email, :email],
          :gender => :gender,
          :birthday => :birthday,
          :timezone => :utcOffset,
          :home_country => "address:country",
          :home_locality => "address:locality",
          :home_postal_code => "address:postalCode"
        }
        
        extend ClassMethods
      end
    end
    
    module ClassMethods
      def new_from_rpx(profile_data)
        user = RpxAuthentication.user_model.new
        
        # Each mapping consists of a local and the rpx side.
        # E.g. User.username = rpx_data["preferredUsername"]
        self.rpx_mappings.each do |local, rpx|
          # We normalize the rpx_data key(s) into an array
          rpx = Array(rpx)
          # Check for existence of the User attribute in question
          if user.respond_to?(local)
            # Multiple rpx_data keys can be used as fallbacks, so we loop through
            # all of them until we find data.
            rpx.each do |rpx|
              # Here we split "namespaced" keys à la "name:givenName" up...
              rpx = rpx.is_a?(String) ? rpx.split(":") : [rpx.to_s]
              # ... and walk to the data step-by-step
              data = profile_data
              while key = rpx.shift
                break if not data = data[key]
                user.send(:"#{local}=", data) if rpx.empty?
              end
            end
            
          end
        end
        
        user
      end
      
      # Split into new_from_rpx and create_from_rpx to allow easier customisation
      def create_from_rpx(profile_data)
        user = new_from_rpx(profile_data)
        user.save
        user
      end
    end
    
  end
  
end

# We might constantly get reloaded in development mode.
# In this case we also need to slurp in the config after each reload (mainly to set the API key).
load "#{RAILS_ROOT}/config/initializers/rpx_authentication.rb" if RAILS_ENV == "development"