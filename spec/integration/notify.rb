require File.join(File.dirname(__FILE__),'..','spec_helper')

# Tests against a real Growl server running locally

module NotifyTestHelper

  def register_app_with_notifications(app, *args)
    lines = "GNTP/1.0 REGISTER NONE", "Application-Name: #{app}", ""
    args.each do |arg| 
      lines << "Notification-Name: #{arg}"
      lines << "Notification-Display-Name: #{arg}"
      lines << "Notification-Enabled: True"
    end
    raw = lines.join("\r\n") + "\r\n"
    req = load_request(raw)
    EM.run {
      connect = EM_GNTP::Client.register(req, 'localhost', 23053)
      connect.callback do |resp|
        puts "Note: REGISTER successful"
        EM.stop
      end
      connect.errback do |resp|
        flunk "Expected successful REGISTER response (0), received failure (#{resp[0]})"
        EM.stop
      end
    }
  end
  
  def load_request(str)
    klass = EM_GNTP::Client.anonymous_request_class
    klass.load(str)
  end
  
  def should_send_and_receive_one_response_successfully(req)
    count = 0
    EM.run {

      connect = EM_GNTP::Client.notify(req, 'localhost', 23053)
      connect.callback do |resp|
        count += 1
        puts "Response received back:\n#{resp.inspect}"
        resp[0].to_i.must_equal 0
        EM.stop
      end
      connect.errback do |resp|
        puts "Response received back:\n#{resp.inspect}"
        flunk "Expected successful NOTIFY response (0), received failure (#{resp[0]})"
        EM.stop
      end
      
    }
    count.must_equal 1
  end

  def should_send_and_receive_response_and_callback_successfully(req)
    count = 0
    EM.run {

      connect = EM_GNTP::Client.notify(req, 'localhost', 23053)
      connect.callback do |resp|
        count += 1
        puts "Response received back:\n#{resp.inspect}"
        resp[0].to_i.must_equal 0
      end
      connect.each_callback_response do |resp|
        count += 1
        resp[2].wont_be_nil
        puts "Callback response received back:\n#{resp.inspect}"
        puts "Does this action match what you did? #{resp[2]}"
        EM.stop
      end
      connect.errback do |resp|
        puts "Response received back:\n#{resp.inspect}"
        flunk "Expected successful NOTIFY response (0), received failure (#{resp[0]})"
        EM.stop
      end
      
    }
    count.must_equal 2
  end
  
end

describe 'Sending a NOTIFY request to Growl' do
  describe 'when no callback' do
    include NotifyTestHelper
    
    before do
      @input = <<-__________
GNTP/1.0 NOTIFY NONE
Application-Name: Test Ruby App
Notification-Name: Test Notification 
Notification-Title: Title Goes Here
Notification-ID: #{rand(9999)} 
      
  __________
      @input_req = load_request(@input)
    end
    
    it 'should send and receive one response successfully' do
      register_app_with_notifications("Test Ruby App", "Test Notification")
      puts "Sending request:\n#{@input_req.inspect}"
      should_send_and_receive_one_response_successfully(@input_req)
    end
    
  end
  
  describe 'when callback' do
    include NotifyTestHelper
    
    before do
      @input = <<-__________
GNTP/1.0 NOTIFY NONE
Application-Name: Test Ruby App
Notification-Name: Test Callback
Notification-Title: Waiting for your response
Notification-ID: #{rand(9999)} 
Notification-Callback-Context: Context
Notification-Callback-Context-Type: Type
      
  __________
      @input_req = load_request(@input)
    end
    
    it 'should send and receive one response successfully' do
      register_app_with_notifications("Test Ruby App", "Test Callback")
      puts "Sending request:\n#{@input_req.inspect}"
      should_send_and_receive_response_and_callback_successfully(@input_req)
    end
    
  end
  
  
end


