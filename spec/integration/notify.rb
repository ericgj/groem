require File.join(File.dirname(__FILE__),'..','spec_helper')

# Tests against a real Growl server running locally
# Testing Client

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
      connect.when_ok do |resp|
        count += 1
        puts "Response received back:\n#{resp.inspect}"
        resp[0].to_i.must_equal 0
      end
      connect.when_callback do |resp|
        count += 1
        resp[2].wont_be_empty
        puts "Callback response received back:\n#{resp.inspect}"
        puts "Does this action match what you did? #{resp[2]['Notification-Callback-Result']}"
        EM.stop
      end
      connect.errback do |resp|
        puts "Response received back:\n#{resp.inspect}"
        flunk "Expected successful NOTIFY response (0), received failure (#{resp[0]})"
        EM.stop
      end
      connect.callback { |resp| EM.stop }
      
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


describe 'Sending a non-callback notification from an App' do

  before do
    @app = EM_GNTP::App.new('Rapster')
  end
  
  it 'should send and receive register and notify response successfully' do
    register_count = 0
    notify_count = 0
    callback_count = 0
    @app.when_register do |resp|
      puts "Response received back:\n#{resp.inspect}"
      register_count += 1
      resp[0].to_i.must_equal 0
    end
    
    @app.when_register_failed do |resp|
      puts "Response received back:\n#{resp.inspect}"
      flunk 'Expected OK response from REGISTER, got error connecting or ERROR response'
    end
      
    @app.register do
      header 'X-Something', 'Foo'
      notification :starting, :enabled => 'True', :text => "Starting..."
      notification :finished do |n|
        n.enabled = 'True'
        n.text = 'Finished!'
        n.callback :finished, :type => 'Boolean'
      end
    end
    
    @app.notify(:starting, 'XYZ has started') do |resp|
      puts "Response received back:\n#{resp.inspect}"
      resp.ok? { notify_count += 1 }
      resp.error? { flunk "Expected OK response from NOTIFY, got ERROR #{resp[0]}" }
      resp.callback? { flunk "Expected OK response from NOTIFY, got CALLBACK" }
    end
    
    register_count.must_equal 1
    notify_count.must_equal 1
    callback_count.must_equal 0
  end
  
end


describe 'Sending a callback notification from an App' do

  before do
    @app = EM_GNTP::App.new('Sapster')
  end
  
  it 'should send and receive register and notify response successfully' do
    register_count = 0
    notify_count = 0
    callback_count = 0
    @app.when_register do |resp|
      puts "Response received back:\n#{resp.inspect}"
      register_count += 1
      resp[0].to_i.must_equal 0
    end
    
    @app.when_register_failed do |resp|
      puts "Response received back:\n#{resp.inspect}"
      flunk 'Expected OK response from REGISTER, got error connecting or ERROR response'
    end
      
    @app.register do
      header 'X-Something', 'Foo'
      notification :starting, :enabled => 'True', :text => "Starting..."
      notification :finished do |n|
        n.enabled = 'True'
        n.text = 'Finished!'
        n.callback :finished, :type => 'Boolean'
      end
    end
    
    @app.when_click :finished do |resp|
      puts "Callback received back:\n#{resp.inspect}"
      callback_count += 1
    end
    
    @app.when_close :finished do |resp|
      puts "Callback received back:\n#{resp.inspect}"
      callback_count += 1
    end
    
    @app.when_timedout :finished do |resp|
      puts "Callback received back:\n#{resp.inspect}"
      callback_count += 1
    end
    
    @app.notify(:finished, 'XYZ has finished') do |resp|
      puts "Response received back:\n#{resp.inspect}"
      resp.ok? { notify_count += 1 }
      resp.error? { flunk "Expected OK response from NOTIFY, got ERROR #{resp[0]}" }
      resp.callback? { flunk "Expected OK response from NOTIFY, got CALLBACK" }
    end
    
    register_count.must_equal 1
    notify_count.must_equal 1
    callback_count.must_equal 1
  end
  
end
