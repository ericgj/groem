require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::Client' do

  describe 'REGISTER request, handle OK response' do
  
    before do
      @p_svr = DummyServerHelper.fork_server(:register => '-OK')

      @input_env = { 'protocol' => 'GNTP',
                     'version' => '1.0',
                     'request_method' => 'REGISTER',
                     'encryption_id' => 'NONE'
                    }
      @input_hdrs = {'Application-Name' => 'SurfWriter',
                     'Application-Icon' => 'http://www.site.org/image.jpg'
                    }
                    
      @input_notifs = { 'Download Complete' => {
                            'Notification-Display-Name' => 'Download completed',
                            'Notification-Enabled' => 'True',
                            'X-Language' => 'English',
                            'X-Timezone' => 'PST'
                        }
                      }
                      
      @input = MarshalHelper.dummy_request(
                   @input_env, @input_hdrs, @input_notifs)
      
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      
    end

    after do
      DummyServerHelper.kill_server(@p_svr)
    end
        
    it 'should receive back one OK response' do
      ok_count = 0
      error_count = 0
      callback_count = 0
      EM.run {
        puts "Client sending request"
        connect = EM_GNTP::Client.register(@input, 'localhost', DummyServerHelper::DEFAULT_PORT)
        
        connect.when_ok do |resp|
          puts "Client received OK response"
          ok_count += 1
          resp[0].to_i.must_equal 0
          resp[2].must_be_empty
        end
        
        connect.errback do |resp|
          puts "Client received error response"
          error_count += 1
        end
        
        connect.when_callback do |resp|
          puts "Client received callback response"
          callback_count += 1
        end
        
        EM.add_timer(1) { 
          count = ok_count + error_count + callback_count
          flunk "Expected one response, #{count} received" unless count == 1
          flunk 'Expected OK response, none received' unless ok_count == 1
          EM.stop 
        }
      }
    end
        
    
  end

  describe 'REGISTER request, handle ERROR response' do
  
    before do
      @error_code = 500
      @p_svr = DummyServerHelper.fork_server(:register => ['-ERROR', @error_code])

      @input_env = { 'protocol' => 'GNTP',
                     'version' => '1.0',
                     'request_method' => 'REGISTER',
                     'encryption_id' => 'NONE'
                    }
      @input_hdrs = {'Application-Name' => 'SurfWriter',
                     'Application-Icon' => 'http://www.site.org/image.jpg'
                    }
                    
      @input_notifs = { 'Download Complete' => {
                            'Notification-Display_name' => 'Download completed',
                            'Notification-Enabled' => 'True',
                            'X-Language' => 'English',
                            'X-Timezone' => 'PST'
                        }
                      }
                      
      @input = MarshalHelper.dummy_request(
                   @input_env, @input_hdrs, @input_notifs)
      
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      
    end

    after do
      DummyServerHelper.kill_server(@p_svr)
    end
    
    it 'should receive back one error response' do
      ok_count = 0
      error_count = 0
      callback_count = 0
      EM.run {
        puts "Client sending request"
        connect = EM_GNTP::Client.register(@input, 'localhost', DummyServerHelper::DEFAULT_PORT)
        
        connect.when_ok do |resp|
          puts "Client received OK response"
          ok_count += 1
        end
        
        connect.errback do |resp|
          puts "Client received error response"
          error_count += 1
          resp[0].to_i.must_equal @error_code.to_i
          resp[2].must_be_empty
        end
        
        connect.when_callback do |resp|
          puts "Client received callback response"
          callback_count += 1
        end
        
        EM.add_timer(1) { 
          count = ok_count + error_count + callback_count
          flunk "Expected one response, #{count} received" unless count == 1
          flunk 'Expected ERROR response, none received' unless error_count == 1
          EM.stop 
        }
      }
    end
        
  end
  
  describe 'NOTIFY request, no callback specified, handle OK response' do
    #TODO: basically the same as REGISTER -OK
  end
  
  describe 'NOTIFY request, no callback specified, handle ERROR response' do
    #TODO: basically the same as REGISTER -ERROR
  end
  
  describe 'NOTIFY request, callback specified, handle OK and CALLBACK response' do
  
    before do
      @callback_delay = 3
      @callback_result = 'CLICKED'
      @p_svr = DummyServerHelper.fork_server(:notify => '-OK', 
                                             :callback => [@callback_result, @callback_delay])

      @input_env = { 'protocol' => 'GNTP',
                     'version' => '1.0',
                     'request_method' => 'NOTIFY',
                     'encryption_id' => 'NONE'
                    }
      @input_hdrs = {'Application-Name' => 'SurfWriter',
                     'Notification-ID' => '999',
                     'Notification-Callback-Context' => 'default',
                     'Notification-Callback-Context-Type' => 'confirm'
                    }
                                          
      @input = MarshalHelper.dummy_request(
                   @input_env, @input_hdrs, {})
      
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      
      @ok_count = 0
      @error_count = 0
      @callback_count = 0
      
      EM.run {
        puts "Client sending request"
        connect = EM_GNTP::Client.notify(@input, 'localhost', DummyServerHelper::DEFAULT_PORT)
        
        connect.when_ok do |resp|
          puts "Client received OK response"
          @ok_count += 1
          resp[0].to_i.must_equal 0
          resp[2].must_be_empty
        end
        
        connect.errback do |resp|
          puts "Client received error response"
          @error_count += 1
        end
        
        connect.when_callback do |resp|
          puts "Client received callback response"
          resp[2]['Notification-Callback-Result'].must_equal @callback_result
          @callback_count += 1
        end
        
        EM.add_timer(@callback_delay + 1) { EM.stop }
     }
      
    end

    after do
      DummyServerHelper.kill_server(@p_svr)
    end
    
    it 'should receive back one OK response' do
      @ok_count.must_equal 1 
    end

    it 'should receive back one callback response after delay' do
      @callback_count.must_equal 1 
    end

    it 'should receive no error response' do
      @error_count.must_equal 0
    end
    
  end
  
  describe 'NOTIFY request, callback specified, handle ERROR response' do
  
    before do
      @callback_delay = 3
      @callback_result = 'CLICKED'
      @error_code = '303'
      @p_svr = DummyServerHelper.fork_server(:notify => ['-ERROR', @error_code], 
                                             :callback => [@callback_result, @callback_delay])

      @input_env = { 'protocol' => 'GNTP',
                     'version' => '1.0',
                     'request_method' => 'NOTIFY',
                     'encryption_id' => 'NONE'
                    }
      @input_hdrs = {'Application-Name' => 'SurfWriter',
                     'Notification-ID' => '999',
                     'Notification-Callback-Context' => 'default',
                     'Notification-Callback-Context-Type' => 'confirm'
                    }
                                          
      @input = MarshalHelper.dummy_request(
                   @input_env, @input_hdrs, {})
      
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      
      @ok_count = 0
      @error_count = 0
      @callback_count = 0
      
      EM.run {
        puts "Client sending request"
        connect = EM_GNTP::Client.notify(@input, 'localhost', DummyServerHelper::DEFAULT_PORT)
        
        connect.when_ok do |resp|
          puts "Client received OK response"
          @ok_count += 1
        end
        
        connect.errback do |resp|
          puts "Client received error response"
          @error_count += 1
          resp[0].to_i.must_equal @error_code.to_i
          resp[2].must_be_empty
        end
        
        connect.when_callback do |resp|
          puts "Client received callback response"
          @callback_count += 1
        end
        
        EM.add_timer(@callback_delay + 1) { EM.stop }
     }
      
    end

    after do
      DummyServerHelper.kill_server(@p_svr)
    end
    
    it 'should receive back no OK response' do
      @ok_count.must_equal 0 
    end

    it 'should receive back no callback response' do
      @callback_count.must_equal 0 
    end

    it 'should receive one error response' do
      @error_count.must_equal 1
    end
      
  end
  
  describe 'NOTIFY request, callback specified, handle only CALLBACK response' do
  
    before do
      @callback_delay = 3
      @callback_result = 'CLICKED'
      @p_svr = DummyServerHelper.fork_server(:notify => '-OK', 
                                             :callback => [@callback_result, @callback_delay])

      @input_env = { 'protocol' => 'GNTP',
                     'version' => '1.0',
                     'request_method' => 'NOTIFY',
                     'encryption_id' => 'NONE'
                    }
      @input_hdrs = {'Application-Name' => 'SurfWriter',
                     'Notification-ID' => '999',
                     'Notification-Callback-Context' => 'default',
                     'Notification-Callback-Context-Type' => 'confirm'
                    }
                                          
      @input = MarshalHelper.dummy_request(
                   @input_env, @input_hdrs, {})
      
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      
      @error_count = 0
      @callback_count = 0
      
      EM.run {
        puts "Client sending request"
        connect = EM_GNTP::Client.notify(@input, 'localhost', DummyServerHelper::DEFAULT_PORT)
        
        connect.errback do |resp|
          puts "Client received error response"
          @error_count += 1
        end
        
        connect.when_callback do |resp|
          puts "Client received callback response"
          puts resp.inspect
          resp[2]['Notification-Callback-Result'].must_equal @callback_result
          @callback_count += 1
        end
        
        EM.add_timer(@callback_delay + 1) { EM.stop }
     }
      
    end

    after do
      DummyServerHelper.kill_server(@p_svr)
    end
    
    it 'should receive back one callback response after delay' do
      @callback_count.must_equal 1 
    end

    it 'should receive no error response' do
      @error_count.must_equal 0
    end
    
  end
  
end
