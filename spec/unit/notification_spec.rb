require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::Notification #[]' do

  describe 'after initializing' do
    it 'should set the notification_name header based on input' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject['headers']['notification_name'].must_equal 'verb'
    end
 
    it 'should not set the notification_title header if none passed' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject['headers'].keys.wont_include 'notification_title'
    end
  
    it 'should set the notification_title header based on input' do
      @subject = EM_GNTP::Notification.new('verb', 'title')
      @subject['headers']['notification_title'].must_equal 'title'
    end
    
    it 'should default the environment when no options passed' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject['environment'].must_equal EM_GNTP::Notification::DEFAULT_ENV
    end
    
    it 'should merge keys from input environment option into default environment' do
      input = {'version' => '1.2', 
                'request_method' => 'HELLO',
                'encryption_id' => 'ABC'
               }
      @subject = EM_GNTP::Notification.new('verb', {:environment => input})
      @subject['environment'].must_equal EM_GNTP::Notification::DEFAULT_ENV.merge(input)
    end
    
    it 'should set each notify option in headers hash prefixed by \'notification_\', besides environment' do
      opts = {:environment => {}, 
               :title => 'what', 
               :text => 'False', 
               :sticky => 'True'
              }
      @subject = EM_GNTP::Notification.new('verb', opts)
      @subject['headers']['notification_title'].must_equal 'what'
      @subject['headers']['notification_text'].must_equal 'False'
      @subject['headers']['notification_sticky'].must_equal 'True'
      @subject['headers'].keys.wont_include 'environment'
      @subject['headers'].keys.wont_include 'notification_environment'
    end
    
    it 'should set application_name option in headers hash' do
      opts = {:environment => {}, 
               :application_name => 'Obama'
              }
      @subject = EM_GNTP::Notification.new('verb', opts)
      @subject['headers']['application_name'].must_equal 'Obama'
      @subject['headers'].keys.wont_include 'notification_application_name'
    end
    
    it 'should set automatic notification_id in headers hash' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject['headers'].keys.must_include 'notification_id'
    end
    
  end

  describe 'after setting header' do
  
    it 'should add the header to the headers hash based on input' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject.header('x_header', 'boo')
      @subject['headers']['x_header'].must_equal 'boo'
    end
  
  end
  
  describe 'after setting callback' do
  
    it 'should add the notification_callback_context header to the headers hash' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject.callback 'success'
      @subject['headers']['notification_callback_context'].must_equal 'success'
    end
  
    it 'should add the notification_callback_context_type header to the headers hash, when :type passed as an option' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject.callback 'success', :type => 'test'
      @subject['headers']['notification_callback_context_type'].must_equal 'test'
    end

    it 'should add the notification_callback_target header to the headers hash, when :target passed as an option' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject.callback 'success', :target => '10.10.0.2'
      @subject['headers']['notification_callback_target'].must_equal '10.10.0.2'
    end

  end
  
  describe 'after reset!' do
  
    it 'should not set the same notification_id' do
      @subject = EM_GNTP::Notification.new('verb')
      id = @subject['headers']['notification_id']
      @subject.reset!
      @subject['headers']['notification_id'].wont_equal id
    end
    
  end
  
end