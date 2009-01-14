require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe RpxAuthentication, 'Configuration' do
  
  it "should expose api_key" do
    RpxAuthentication.api_key = "foobar"
    RpxAuthentication.api_key.should eql("foobar")
  end
  
  it "should expose user_model" do
    class DummyClass; end
    RpxAuthentication.user_model = DummyClass
    RpxAuthentication.user_model.should be(DummyClass)
  end

end


    

describe RpxAuthentication::Gateway, 'RPXnow.com gateway' do
  
  it "should talk to the right host" do
    RpxAuthentication::Gateway.base_uri.should eql("http://rpxnow.com")
  end
  
  it "should send a well formed authentication request" do
    RpxAuthentication.api_key = "api_key"
    
    params = ["/api/v2/auth_info", {
      :query => {
        :apiKey => "api_key",
        :token => "token",
        :extended => "true"
      } }
    ]

    RpxAuthentication::Gateway.should_receive(:post).with(*params).and_return(true)
    RpxAuthentication::Gateway.authenticate("token")
  end
  
  it "should detect failures and incomplete responses" do
    responses = [
      { "stat" => "fail" },
      { "err" => { "msg" => "Invalid parameter: apiKey", "code" => 1}, "stat" => "fail" },
      { "stat" => "ok" }, # no profile info
      { "profile" => {} },
      "profile",
      { "stat" => "ok", "profile" => { "preferredUsername" => "TestUser" } }, # no identifier
      { "stat" => "ok", "profile" => { "identifier" => "" } }, # no identifier
      { }
    ]
    
    RpxAuthentication::Gateway.should_receive(:post).exactly(responses.size).times.and_return(*responses)
    responses.size.times { RpxAuthentication::Gateway.authenticate("token").should be(false) }
  end
  
  it "should pass profile data through from rpxnow.com" do
    responses = [
      { "stat" => "ok",
        "profile" => {
          "identifier" => "https://www.idprovider.com/TestUser"
        }
      },
      { "stat" => "ok",
        "profile" => {
          "name" => {
            "givenName" => "Test",
            "familyName" => "User"
          },
          "identifier" => "https://www.idprovider.com/TestUser"
        }
      }
    ]
    
    RpxAuthentication::Gateway.should_receive(:post).exactly(2).times.and_return(*responses)
    responses.each do |response|
      result = RpxAuthentication::Gateway.authenticate("token")
      result["identifier"].should eql("https://www.idprovider.com/TestUser")
      result["name"].should eql(response["profile"]["name"]) if (response.include?("name"))
    end
  end

end