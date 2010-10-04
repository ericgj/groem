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
      @input_hdrs = {'application_name' => 'SurfWriter',
                     'application_icon' => 'http://www.site.org/image.jpg'
                    }
                    
      @input_notifs = { 'Download Complete' => {
                            'notification_display_name' => 'Download completed',
                            'notification_enabled' => 'True',
                            'x_language' => 'English',
                            'x_timezone' => 'PST'
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
      count = 0
      EM.run {
        puts "Client sending request:\n#{@input.dump}"
        connect = EM_GNTP::Client.register(@input)
        
        connect.each_ok_response do |resp|
          puts "Client received OK response"
          count += 1
          resp[0].to_i.must_equal 0
        end
        
        connect.each_error_response do |resp|
          puts "Client received error response"
          count += 1
        end
        
        connect.each_callback_response do |resp|
          puts "Client received callback response"
          count += 1
        end
        
        EM.add_timer(1) { 
          flunk "Expected one response, #{count} received" unless count == 1
          flunk 'Expected OK response, none received' unless count > 0
          EM.stop 
        }
      }
    end
        
    
  end

  describe 'REGISTER request, handle ERROR response' do

  end
  
  describe 'NOTIFY request, no callback specified, handle OK response' do
  
  end
  
  describe 'NOTIFY request, no callback specified, handle ERROR response' do
  
  end
  
  describe 'NOTIFY request, callback specified, handle OK and CALLBACK response' do
  
  end
  
  describe 'NOTIFY request, callback specified, handle ERROR response' do
  
  end
  
end
