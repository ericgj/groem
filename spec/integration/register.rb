require File.join(File.dirname(__FILE__),'..','spec_helper')

# Tests against a real Growl server running locally

module RegisterTestHelper

  def load_request(str)
    klass = EM_GNTP::Client.anonymous_request_class
    klass.load(str)
  end
  
  def should_send_and_receive_one_response_successfully(req)
    count = 0
    EM.run {

      connect = EM_GNTP::Client.register(req, 'localhost', 23053)
      connect.callback do |resp|
        count += 1
        puts "Response received back:\n#{resp.inspect}"
        resp[0].to_i.must_equal 0
        EM.stop
      end
      connect.errback do |resp|
        puts "Response received back:\n#{resp.inspect}"
        flunk "Expected successful REGISTER response (0), received failure (#{resp[0]})"
      end
      
    }
    count.must_equal 1
  end

end

describe 'Sending a REGISTER request to Growl' do
  describe 'when one notification' do
    include RegisterTestHelper
    
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
      @input_req = load_request(@input)
      puts "Sending request:\n#{@input_req.inspect}"
    end
    
    it 'should send and receive one response successfully' do
      should_send_and_receive_one_response_successfully(@input_req)
    end
    
  end

  describe 'when three notifications' do
    include RegisterTestHelper
    
    before do
      @input = <<-__________
  GNTP/1.0 REGISTER NONE
  Application-Name: Test Ruby App 
  
  Notification-Name: Download Complete 
  Notification-Display-Name: Download completed 
  Notification-Enabled:True 
  X-Language : English 
  X-Timezone: EDT 
  
  Notification-Name: Download Started
  Notification-Display-Name: Download starting
  Notification-Enabled: False
  Notification-Sticky: True
      
  Notification-Name: Download Halfway
  Notification-Display-Name: Almost there...
  Notification-Enabled: True
  Notification-Sticky: False
  Notification-Priority: 0
  
  __________
      @input_req = load_request(@input)
      puts "Sending request:\n#{@input_req.inspect}"
    end
    
    it 'should send and receive one response successfully' do
      should_send_and_receive_one_response_successfully(@input_req)
    end
    
  end
  
end

# Testing App

describe 'Registering an App with Growl' do

  before do
    @app = EM_GNTP::App.new('Apster')
  end
  
  it 'should send and receive one response successfully' do
    count = 0
    @app.when_register do |resp|
      puts "Response received back:\n#{resp.inspect}"
      count += 1
      resp[0].to_i.must_equal 0
    end
    
    @app.when_register_failed do |resp|
      puts "Response received back:\n#{resp.inspect}"
      flunk 'Expected OK response, got error connecting or ERROR response'
    end
      
    @app.register do
      header 'X-Something', 'Foo'
      notification :starting, :enabled => 'False', :text => "Starting..."
      notification :finished do |n|
        n.enabled = 'True'
        n.text = 'Finished!'
        n.callback :finished, :type => 'Boolean'
      end
    end
    
    count.must_equal 1
  end
  
  
end