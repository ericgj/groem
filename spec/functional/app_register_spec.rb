require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'Groem::App #register' do

  describe 'with one notification, server responds OK' do
  
    before do
      @p_svr = DummyServerHelper.fork_server(:register => '-OK')
      Groem::Client.response_class = MarshalHelper.dummy_response_class
      @subject = Groem::App.new('test',:port => DummyServerHelper::DEFAULT_PORT)
    end
    
    after do
      DummyServerHelper.kill_server(@p_svr)
    end

    it 'should receive back one OK response' do
      count = 0
      @subject.when_register do |resp|
        count += 1
        resp[0].to_i.must_equal 0
        resp[2].must_be_empty
        count.must_equal 1
      end
      
      @subject.when_register_failed do |resp|
        count.must_equal 1
        flunk 'Expected OK response, got error connecting or ERROR response'
      end
      
      @subject.register do
        notification 'hello' do end
      end
    
    end
    
    it 'should return OK response' do
      ret = \
        @subject.register do
          notification 'hello' do end
        end
        
      ret.class.must_be_same_as Groem::Response
      ret[0].to_i.must_equal 0
      ret[2].must_be_empty
    end
    
  end
  
  describe 'with three notifications, server responds OK' do
  
    before do
      @p_svr = DummyServerHelper.fork_server(:register => '-OK')
      Groem::Client.response_class = MarshalHelper.dummy_response_class
      @subject = Groem::App.new('test',:port => DummyServerHelper::DEFAULT_PORT)
    end
    
    after do
      DummyServerHelper.kill_server(@p_svr)
    end

    it 'should receive back one OK response' do
      count = 0
      @subject.when_register do |resp|
        count += 1
        resp[0].to_i.must_equal 0
        resp[2].must_be_empty
        count.must_equal 1
      end
      
      @subject.when_register_failed do |resp|
        count.must_equal 1
        flunk 'Expected OK response, got error connecting or ERROR response'
      end
      
      @subject.register do
        notification 'hello' do end
        notification 'goodbye' do |n|
          n.text = 'farewell lovey'
          n.sticky = 'True'
          n.title = 'Bon Voyage'
        end
        notification 'wait' do |n|
          n.callback 'default', :type => 'confirm'
          n.header 'x_something_else', 'tomorrow'
        end
      end
    
    end
    
    it 'should return OK response' do
      ret = \
      @subject.register do
        notification 'hello' do end
        notification 'goodbye' do |n|
          n.text = 'farewell lovey'
          n.sticky = 'True'
          n.title = 'Bon Voyage'
        end
        notification 'wait' do |n|
          n.callback 'default', :type => 'confirm'
          n.header 'x_something_else', 'tomorrow'
        end
      end
        
      ret.class.must_be_same_as Groem::Response
      ret[0].to_i.must_equal 0
      ret[2].must_be_empty
    end
    
  end
  
end
