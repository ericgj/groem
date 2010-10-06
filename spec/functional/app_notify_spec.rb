require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::App #notify' do

  describe 'with no callback' do
  
    before do
      @p_svr = DummyServerHelper.fork_server(:notify => '-OK')
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      @subject = EM_GNTP::App.new('test', :port => DummyServerHelper::DEFAULT_PORT)
    end
    
    after do
      DummyServerHelper.kill_server(@p_svr)
    end

    it 'should receive back one OK response from notify' do
      count = 0
      
      @subject.register do
        notification 'hello' do end
      end
      
      @subject.notify('hello') do |resp|
        count += 1
        resp[0].to_i.must_equal 0
        count.must_equal 1
      end
      
    end
  end

  describe 'with callback' do
    #TODO
  end
  
  describe 'when notification hasnt been specified' do

    before do
      @p_svr = DummyServerHelper.fork_server(:notify => '-OK')
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      @subject = EM_GNTP::App.new('test', :port => DummyServerHelper::DEFAULT_PORT)
    end
    
    after do
      DummyServerHelper.kill_server(@p_svr)
    end
  
    it 'should return nil' do
      
      @subject.register do
        notification 'hello' do end
      end
      
      @subject.notify('goodbye') do end.must_be_nil
      
    end
    
  end
  
end