require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::Marshal::Request#load' do

  describe 'when valid REGISTER request with one notification and no binaries' do
    
    before do
      @input = <<-__________
GNTP/1.0 REGISTER NONE
Application-Name: SurfWriter 
Application-Icon: http://www.site.org/image.jpg 
X-Creator: Apple Software 
X-Application-ID: 08d6c05a21512a79a1dfeb9d2a8f262f 
Notifications-Count: 1 

Notification-Name: Download Complete 
Notification-Display-Name: Download completed 
Notification-Enabled: True 
X-Language: English 
X-Timezone: PST 


__________
      dummy = Class.new { include(EM_GNTP::Marshal::Request) }
      @subject = dummy.new.load(@input)
    end
    
    it 'should return a three element array' do
      @subject.size.must_equal 3
    end
    
    it 'first element should have version == 1.0' do
      @subject[0]['version'].must_equal '1.0'
    end

    it 'first element should have request_method == REGISTER' do
      @subject[0]['request_method'].must_equal 'REGISTER'
    end
    
    it 'second element should have application_name == SurfWriter' do
      @subject[1]['application_name'].must_equal 'SurfWriter'
    end
    
    it 'second element should have notifications_count == 1' do
      @subject[1]['notifications_count'].must_equal '1'
    end
    
    it 'third element should have 1 key' do
      @subject[2].keys.size.must_equal 1
    end
    
    it 'third element should have key \'Download Complete\'' do
      @subject[2]['Download Complete'].wont_be_nil
    end
    
    it '\'Download Complete\' notification should have notification_display_name == \'Download completed\'' do
      @subject[2]['Download Complete']['notification_display_name'].must_equal 'Download completed'
    end
    
    it '\'Download Complete\' notification should have x_timezone == \'PST\'' do
      @subject[2]['Download Complete']['x_timezone'].must_equal 'PST'
    end
    
    it 'second element should not have x_timezone key' do
      @subject[1].has_key?('x_timezone').must_equal false
    end
    
  end
    
  describe 'when valid REGISTER request with three notifications and no binaries' do
    
    before do
      @input = <<-__________
GNTP/1.0 REGISTER NONE
Application-Name: SurfWriter 
Application-Icon: http://www.site.org/image.jpg 
X-Creator: Apple Software 
X-Application-ID: 08d6c05a21512a79a1dfeb9d2a8f262f 
Notifications-Count: 3 

Notification-Name: Download Complete 
Notification-Display-Name: Download completed 
Notification-Enabled: True 
X-Language: English 
X-Timezone: PST 

Notification-Name: Download Started 
Notification-Display-Name: Download starting 
Notification-Enabled: False 
X-Timezone: GMT 

Notification-Name: Download Error 
Notification-Display-Name: Error downloading 
Notification-Enabled: True 
X-Language: Spanish 

__________
      dummy = Class.new { include(EM_GNTP::Marshal::Request) }
      @subject = dummy.new.load(@input)
    end
    
    it 'should return a three element array' do
      @subject.size.must_equal 3
    end
      
    it 'third element should have 3 keys' do
      @subject[2].keys.size.must_equal 3
    end
    
    it 'third element should have key \'Download Complete\'' do
      @subject[2]['Download Complete'].wont_be_nil
    end

    it 'third element should have key \'Download Started\'' do
      @subject[2]['Download Started'].wont_be_nil
    end
    
    it 'third element should have key \'Download Error\'' do
      @subject[2]['Download Error'].wont_be_nil
    end

    it '\'Download Complete\' notification should have notification_display_name == \'Download completed\'' do
      @subject[2]['Download Complete']['notification_display_name'].must_equal 'Download completed'
    end

    it '\'Download Started\' notification should have notification_enabled == \'False\'' do
      @subject[2]['Download Started']['notification_enabled'].must_equal 'False'
    end    
    
    it '\'Download Error\' notification should have x_language == \'Spanish\'' do
      @subject[2]['Download Error']['x_language'].must_equal 'Spanish'
    end    

    it '\'Download Started\' notification should not have x_language key' do
      @subject[2]['Download Started'].has_key?('x_language').must_equal false
    end    
    
    it '\'Download Error\' notification should not have x_timezone key' do
      @subject[2]['Download Error'].has_key?('x_timezone').must_equal false
    end    
    
  end
  
  describe 'when valid NOTIFY request with no binaries' do
    
  end
  
end
  
  
describe 'EM_GNTP::Marshal::Response#load' do
  
  
  describe 'when valid REGISTER response -OK' do
  
  end
  
  describe 'when valid REGISTER response -ERROR' do
  
  end
  
  describe 'when valid NOTIFY response -OK' do
  
  end
  
  describe 'when valid NOTIFY response -ERROR' do
  
  end
  
end
