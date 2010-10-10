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
        n.callback 'First', :type => '1'
      end
    end
   
    app.when_click :type => '2' do |resp|
      cb_count += 1
    end
        
    app.when_click 'Second' do |resp|
      cb_count += 1
    end
    
    app.when_click 'First' do |resp|
      flunk 'Expected callback context \'Second\', got \'First\''
    end
    
    app.when_click :type => '1' do |resp|
      flunk 'Expected callback context type \'2\', got \'1\''
    end
        
    app.notify('Foo', :callback => {:context => 'Second', :type => '2'})

    cb_count.must_equal 2
  end

  it 'should trigger callback with ad-hoc state, but not change state of registered callback' do
  
    app = @subject
    app.register do
      notification 'Foo' do |n|
        n.display_name = 'Hoo'
        n.callback 'First', :type => '1'
      end
    end
    
    app.when_click do |resp|
      puts resp[0..2].inspect
      resp.context.must_equal 'Second'
      resp.context_type.must_equal '2'
    end
    
    app.notify('Foo', :display_name => 'Who',
                      :callback => {:context => 'Second', :type => '2'})
    
    app.notifications['Foo'].display_name.must_equal 'Hoo'
    app.notifications['Foo'].callback_context.must_equal 'First'
    app.notifications['Foo'].callback_type.must_equal '1'
    
  end
  
end