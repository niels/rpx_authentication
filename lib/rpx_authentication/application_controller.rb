module RpxAuthentication
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
end