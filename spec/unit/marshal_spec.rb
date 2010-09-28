require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::Marshal#load, requests' do

  describe 'when valid REGISTER request with no binaries' do
    
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
      dummy = Class.new { include(EM_GNTP::Marshal) }
      @subject = dummy.new.load(@input)
    end
    
    it 'should return a three element array' do
      @subject.size.must_equal 3
    end
    
    it 'first element should be nil' do
      @subject[0].must_be_nil
    end
    
    it 'second element should have version == 1.0' do
      @subject[1]['version'].must_equal '1.0'
    end

    it 'second element should have request_method == REGISTER' do
      @subject[1]['request_method'].must_equal 'REGISTER'
    end
    
    it 'second element should have response_method nil' do
      @subject[1]['request_method'].must_be_nil
    end

    it 'third element should have application_name == SurfWriter' do
      @subject[2]['application_name'].must_equal 'SurfWriter'
    end
    
  end
    
  describe 'when valid NOTIFY request with no binaries' do
    
  end
  
end
  
  
describe 'EM_GNTP::Marshal#load, responses' do
  
  
  describe 'when valid REGISTER response -OK' do
  
  end
  
  describe 'when valid REGISTER response -ERROR' do
  
  end
  
  describe 'when valid NOTIFY response -OK' do
  
  end
  
  describe 'when valid NOTIFY response -ERROR' do
  
  end
  
end
