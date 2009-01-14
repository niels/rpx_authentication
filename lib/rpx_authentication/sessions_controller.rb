module RpxAuthentication
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
end