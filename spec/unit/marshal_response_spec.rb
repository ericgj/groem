require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::Marshal::Response.load' do
  
  
  describe 'when valid REGISTER response -OK' do
    # TODO
  end
  
  describe 'when valid REGISTER response -ERROR' do
    #TODO
  end
  
  describe 'when valid NOTIFY response -OK' do
  
    before do
      @input = <<-__________
GNTP/1.0 -OK NONE
Response-Action: NOTIFY
Application-Name: SurfWriter 
 Notification-ID : 999

__________
      dummy = Class.new { include(EM_GNTP::Marshal::Response) }
      @subject = dummy.load(@input, false)
    end

    it 'should return three element array' do
      @subject.must_be_kind_of Array
      @subject.size.must_equal 3
      puts
      puts '--------- EM_GNTP::Marshal::Response.load when valid NOTIFY response -OK ----------'
      puts @subject.inspect
    end
    
    it 'should return OK status code (== 0)' do
      @subject[0].to_i.must_equal 0
    end
    
    it 'should return headers hash with 3 keys' do
      @subject[1].keys.size.must_equal 3
    end
    
    it 'should return Notification-ID header matching input' do
      @subject[1]['notification_id'].must_equal '999'
    end
    
    it 'should return nil result' do
      @subject[2].must_equal nil
    end
        
  end
  
  describe 'when valid NOTIFY response -ERROR' do
  
    before do
      @input = <<-__________
GNTP/1.0 -ERROR NONE
 Error-Code: 303 
Error-Description : REQUIRED_HEADER_MISSING 
Response-Action: NOTIFY

__________
      dummy = Class.new { include(EM_GNTP::Marshal::Response) }
      @subject = dummy.load(@input, false)
    end

    it 'should return three element array' do
      @subject.must_be_kind_of Array
      @subject.size.must_equal 3
      puts
      puts '--------- EM_GNTP::Marshal::Response.load when valid NOTIFY response -ERROR ----------'
      puts @subject.inspect
    end
    
    it 'should return status code matching input error code (== 303)' do
      @subject[0].to_i.must_equal 303
    end
    
    it 'should return headers hash with 2 keys' do
      @subject[1].keys.size.must_equal 2
    end
    
    it 'should return Response-Action header matching input' do
      @subject[1]['response_action'].must_equal 'NOTIFY'
    end
    
    it 'should not return header for Error-Code' do
      @subject[1].keys.wont_include 'error_code'
    end
    
    it 'should return nil result' do
      @subject[2].must_equal nil
    end
    
  end

  describe 'when valid NOTIFY response -CALLBACK' do
    
    before do
      @input = <<-__________
GNTP/1.0 -CALLBACK NONE
Application-Name: SurfWriter 
Response-Action: NOTIFY
Notification-ID: 999
Notification-Callback-Result : CLICKED
 Notification-Callback-Timestamp: 2010-10-01 22:21:00Z
Notification-Callback-Context :Test
Notification-Callback-Context-Type: Confirm

__________
      dummy = Class.new { include(EM_GNTP::Marshal::Response) }
      @subject = dummy.load(@input, false)
    end
  
    it 'should return three element array' do
      @subject.must_be_kind_of Array
      @subject.size.must_equal 3
      puts
      puts '--------- EM_GNTP::Marshal::Response.load when valid NOTIFY response -CALLBACK ----------'
      puts @subject.inspect
    end
    
    it 'should return OK status code (== 0)' do
      @subject[0].to_i.must_equal 0
    end
    
    it 'should return headers hash with 6 keys' do
      @subject[1].keys.size.must_equal 6
    end
    
    it 'should return Notification-ID header matching input' do
      @subject[1]['notification_id'].must_equal '999'
    end
    
    it 'should return Notification-Callback-Context-Type matching input' do
      @subject[1]['notification_callback_context_type'].must_equal 'Confirm'
    end
    
    it 'should not return header for Notification-Callback-Result' do
      @subject[1].keys.wont_include 'notification_callback_result'
    end
    
    it 'should return result matching input' do
      @subject[2].must_equal 'CLICKED'
    end
    
  end
  
end
