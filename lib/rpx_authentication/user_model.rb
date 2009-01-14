module RpxAuthentication  
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
  
