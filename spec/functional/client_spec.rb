require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::Client' do

  describe 'REGISTER request, handle OK response' do
  
    before do
      @p_svr = fork {
        puts '-------------- forked server process ------------------'
        EM_GNTP::Dummy::Server.respond_to_register_with '-OK'
        EM.run {
          Signal.trap("INT") { EM.next_tick { EM.stop } }
          EM_GNTP::Dummy::Server.listen
        }
        puts '-------------- forked server process ending -----------'
      }
      #Process.detach(@p_svr)

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
      Process.kill("INT", @p_svr)
      sleep 2
      #system("ps -p #{@p_svr}")
    end
    
    it 'should receive back one OK response' do
      EM.run {
        puts "Client sending request:\n#{@input.dump}"
        connect = EM_GNTP::Client.register(@input)
        
        connect.each_ok_response do |resp| 
          @received = true
          resp[0].to_i.must_equal 0
        end
        
        EM.add_timer(3) { 
          flunk 'Expected OK response, none received' unless @received
          EM.stop 
        }
      }
    end
        
    
  end
  
end
