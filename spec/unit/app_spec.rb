require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::App #[]' do

  describe 'after initializing' do
    
    it 'should set the application_name header based on input' do
      @subject = EM_GNTP::App.new('thing')
      @subject['headers']['Application-Name'].must_equal 'thing'
    end
    
    it 'should default the environment when no options passed' do
      @subject = EM_GNTP::App.new('thing')
      @subject['environment'].must_equal EM_GNTP::App::DEFAULT_ENV
    end
    
    it 'should merge keys from input environment option into default environment' do
      input = {'version' => '1.2', 
                'request_method' => 'HELLO',
                'encryption_id' => 'ABC'
               }
      @subject = EM_GNTP::App.new('thing', {:environment => input})
      @subject['environment'].must_equal EM_GNTP::App::DEFAULT_ENV.merge(input)
    end
    
    it 'should set each option in headers hash besides environment, host, and port' do
      opts = {:environment => {}, 
               :host => 'foo', 
               :port => 12345,
               :x_option_1 => '1', 
               :x_option_2 => '2', 
               :x_option_3 => '3'
              }
      @subject = EM_GNTP::App.new('thing', opts)
      @subject['headers'].must_equal(
        {'Application-Name' => 'thing',
         'X-Option-1' => '1',
         'X-Option-2' => '2',
         'X-Option-3' => '3'
        }
      )
    end

    it 'should initialize the notifications hash to empty' do
      @subject = EM_GNTP::App.new('thing')
      @subject['notifications'].must_equal({})
    end
    
  end
  
  describe 'after setting header' do
  
    it 'should add the header to the headers hash based on input' do
      @subject = EM_GNTP::App.new('thing')
      @subject.header('x_header', 'boo')
      @subject['headers']['X-Header'].must_equal 'boo'
    end
  
  end
  
  
  describe 'after setting notification' do
  
    it 'should set the notifications hash with basic info for register' do
      @subject = EM_GNTP::App.new('thing')
      @subject.notification 'action' do end
      @subject['notifications'].keys.must_include 'action'
      @subject['notifications']['action'].must_be_empty
    end
        
  end
  
  
end


