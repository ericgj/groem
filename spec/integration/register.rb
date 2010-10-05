require File.join(File.dirname(__FILE__),'..','spec_helper')

# Tests against a real Growl server running locally

describe 'Sending a REGISTER request to Growl' do

  before do
    @input = <<-__________
GNTP/1.0 REGISTER NONE
Application-Name: Test Ruby App 

Notification-Name: Download Complete 
Notification-Display-Name: Download completed 
Notification-Enabled:True 
X-Language : English 
X-Timezone: EDT 
    
__________
    klass = EM_GNTP::Client.anonymous_request_class
    @input_req = klass.load(@input)
    puts "Sending request:\n#{@input_req.dump.inspect}"    
  end
  
  it 'should send and receive one response successfully' do
    count = 0
    EM.run {

      connect = EM_GNTP::Client.register(@input_req, 'localhost', 23053)
      connect.callback do |resp|
        count += 1
        puts "Response received back:\n#{resp.inspect}"
        resp[0].to_i.must_equal 0
        EM.stop
      end
      connect.errback do |resp|
        puts "Response received back:\n#{resp.inspect}"
        flunk "Expected successful REGISTER response, received failure"
      end
      
    }
    count.must_equal 1
  end
  
end
