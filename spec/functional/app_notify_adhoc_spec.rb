require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::App #notify with ad-hoc callback' do

  before do
    @p_svr = DummyServerHelper.fork_server(:callback => ['CLICK', 2])
    EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
    @subject = EM_GNTP::App.new('test', :port => DummyServerHelper::DEFAULT_PORT)
  end
  
  after do
    DummyServerHelper.kill_server(@p_svr)
  end    

  it 'should receive CLICK callback matching ad-hoc callback spec' do
    ok_count = 0
    cb_count = 0
    
    app = @subject
    app.register do
      notification 'Foo' do |n|
        n.display_name = 'Hoo'
        n.callback 'You', :type => 'shiny'
      end
    end
   
    app.when_click :type => 'dull' do |resp|
      cb_count += 1
    end
        
    app.when_click 'Me' do |resp|
      cb_count += 1
    end
    
    app.when_click 'You' do |resp|
      flunk 'Expected callback context \'Me\', got \'You\''
    end
    
    app.when_click :type => 'shiny' do |resp|
      flunk 'Expected callback context type \'dull\', got \'shiny\''
    end
        
    app.notify('Foo', :display_name => 'Who', :callback => {:context => 'Me', :type => 'dull'})

    cb_count.must_equal 2
    app['notifications']['Foo']['Notification-Display-Name'].must_equal 'Hoo'
  end
  
end