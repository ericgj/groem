require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::App #notify without callbacks' do

  describe 'with one notification' do
  
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
        resp[2].must_be_empty
        count.must_equal 1
      end
      
    end

    it 'should return OK response from notify' do
      
      @subject.register do
        notification 'hello' do end
      end
      
      ret = @subject.notify('hello')
      ret.class.must_be_same_as EM_GNTP::Response
      ret[0].to_i.must_equal 0
      ret[2].must_be_empty
      
    end

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

module AppNotifyCallbacksHelper


  def should_receive_ok_and_callback(app, rslt, timeout, opts = {})
    click_name = opts[:click] || 'CLICK'
    close_name = opts[:close] || 'CLOSE'
    timedout_name = opts[:timedout] || 'TIMEDOUT'
    ok_count = 0
    click_count = 0
    close_count = 0
    timedout_count = 0
    
    EM.run {
      app.register do
        notification 'Foo' do |n|
          n.callback 'You', :type => 'shiny'
        end
      end
     
      app.when_callback click_name do |resp|
        puts "App received callback: #{resp[2]['Notification-Callback-Result']}"
        click_count += 1
        ['CLICK', 'CLICKED'].must_include resp[2]['Notification-Callback-Result']
      end
      
      app.when_callback close_name do |resp|
        puts "App received callback: #{resp[2]['Notification-Callback-Result']}"
        close_count += 1
        ['CLOSE', 'CLOSED'].must_include resp[2]['Notification-Callback-Result']
      end
      
      app.when_callback timedout_name do |resp|
        puts "App received callback: #{resp[2]['Notification-Callback-Result']}"
        timedout_count += 1
        ['TIMEDOUT', 'TIMEOUT'].must_include resp[2]['Notification-Callback-Result']
      end
      
      app.notify('Foo') do |resp|
        ok_count += 1 if resp[0].to_i == 0
        resp[0].to_i.must_equal 0
      end
     
      EM.add_timer(timeout + 1) {
        ok_count.must_equal 1
        case rslt
        when 'CLICK'
          click_count.must_equal 1
          close_count.must_equal 0
          timedout_count.must_equal 0
        when 'CLOSE'
          click_count.must_equal 0
          close_count.must_equal 1
          timedout_count.must_equal 0
        when 'TIMEDOUT'
          click_count.must_equal 0
          close_count.must_equal 0
          timedout_count.must_equal 1
        end
        EM.stop
      }
      
    }
  end

  def should_receive_ok_and_callback_outside_reactor(app, rslt, timeout, opts = {})
    click_name = opts[:click] || 'CLICK'
    close_name = opts[:close] || 'CLOSE'
    timedout_name = opts[:timedout] || 'TIMEDOUT'
    ok_count = 0
    click_count = 0
    close_count = 0
    timedout_count = 0
    
    app.register do
      notification 'Foo' do |n|
        n.callback 'You', :type => 'shiny'
      end
    end
   
    app.when_callback click_name do |resp|
      puts "App received callback: #{resp[2]['Notification-Callback-Result']}"
      click_count += 1
      ['CLICK', 'CLICKED'].must_include resp[2]['Notification-Callback-Result']
    end
    
    app.when_callback close_name do |resp|
      puts "App received callback: #{resp[2]['Notification-Callback-Result']}"
      close_count += 1
      ['CLOSE', 'CLOSED'].must_include resp[2]['Notification-Callback-Result']
    end
    
    app.when_callback timedout_name do |resp|
      puts "App received callback: #{resp[2]['Notification-Callback-Result']}"
      timedout_count += 1
      ['TIMEDOUT', 'TIMEOUT'].must_include resp[2]['Notification-Callback-Result']
    end
    
    app.notify('Foo') do |resp|
      ok_count += 1 if resp[0].to_i == 0
      resp[0].to_i.must_equal 0
    end
  
    ok_count.must_equal 1
    case rslt
    when 'CLICK'
      click_count.must_equal 1
      close_count.must_equal 0
      timedout_count.must_equal 0
    when 'CLOSE'
      click_count.must_equal 0
      close_count.must_equal 1
      timedout_count.must_equal 0
    when 'TIMEDOUT'
      click_count.must_equal 0
      close_count.must_equal 0
      timedout_count.must_equal 1
    end
    
  end

  
  def should_return_ok_response(app)

    app.register do
      notification 'Foo' do |n|
        n.callback 'You', :type => 'shiny'
      end
    end
  
    ret = app.notify('Foo')
    ret.class.must_be_same_as EM_GNTP::Response
    ret[0].to_i.must_equal 0
    ret[2].must_be_empty
  end
  
  
end


describe 'EM_GNTP::App #notify with simple callbacks' do


  describe 'when CLICK callback returned' do
    include AppNotifyCallbacksHelper
    
    before do
      @p_svr = DummyServerHelper.fork_server(:callback => ['CLICK', 2])
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      @subject = EM_GNTP::App.new('test', :port => DummyServerHelper::DEFAULT_PORT)
    end
    
    after do
      DummyServerHelper.kill_server(@p_svr)
    end    
    
    it 'should receive ok and CLICK callback' do
      should_receive_ok_and_callback(@subject, 'CLICK', 2)
    end

    it 'should receive ok and CLICK callback outside reactor' do
      should_receive_ok_and_callback_outside_reactor(@subject, 'CLICK', 2)
    end
    
    it 'should receive ok and CLICK callback using symbolized actions' do
      should_receive_ok_and_callback(@subject, 'CLICK', 2, 
                                     :click => :click, 
                                     :close => :closed, 
                                     :timedout => :timedout)
    end
    
    it 'should receive ok and CLICK callback with alternate action names' do
      should_receive_ok_and_callback(@subject, 'CLICK', 2, 
                                     :click => 'CLICKED', 
                                     :close => 'CLOSED', 
                                     :timedout => 'TIMEOUT')
    end

    it 'should return ok response' do
      should_return_ok_response(@subject)
    end
    
  end
  
  describe 'when CLOSE callback returned' do
    include AppNotifyCallbacksHelper
    
    before do
      @p_svr = DummyServerHelper.fork_server(:callback => ['CLOSE', 2])
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      @subject = EM_GNTP::App.new('test', :port => DummyServerHelper::DEFAULT_PORT)
    end
    
    after do
      DummyServerHelper.kill_server(@p_svr)
    end    
    
    it 'should receive ok and CLOSE callback' do
      should_receive_ok_and_callback(@subject, 'CLOSE', 2)
    end
    
    it 'should receive ok and CLOSE callback using symbolized actions' do
      should_receive_ok_and_callback(@subject, 'CLOSE', 2, 
                                     :click => :click, 
                                     :close => :closed, 
                                     :timedout => :timedout)
    end
    
    it 'should receive ok and CLOSE callback with alternate action names' do
      should_receive_ok_and_callback(@subject, 'CLOSE', 2, 
                                     :click => 'CLICKED', 
                                     :close => 'CLOSED', 
                                     :timedout => 'TIMEOUT')
    end

    it 'should return ok response' do
      should_return_ok_response(@subject)
    end

  end
  
  describe 'when TIMEDOUT callback returned' do
    include AppNotifyCallbacksHelper
    
    before do
      @p_svr = DummyServerHelper.fork_server(:callback => ['TIMEDOUT', 2])
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      @subject = EM_GNTP::App.new('test', :port => DummyServerHelper::DEFAULT_PORT)
    end
    
    after do
      DummyServerHelper.kill_server(@p_svr)
    end    
    
    it 'should receive ok and TIMEDOUT callback' do
      should_receive_ok_and_callback(@subject, 'TIMEDOUT', 2)
    end
      
    it 'should receive ok and TIMEDOUT callback using symbolized actions' do
      should_receive_ok_and_callback(@subject, 'TIMEDOUT', 2, 
                                     :click => :click, 
                                     :close => :closed, 
                                     :timedout => :timedout)
    end
    
    it 'should receive ok and TIMEDOUT callback with alternate action names' do
      should_receive_ok_and_callback(@subject, 'TIMEDOUT', 2, 
                                     :click => 'CLICKED', 
                                     :close => 'CLOSED', 
                                     :timedout => 'TIMEOUT')
    end

    it 'should return ok response' do
      should_return_ok_response(@subject)
    end
    
  end
  
end


describe 'EM_GNTP::App #notify with routed callbacks' do

    before do
      @p_svr = DummyServerHelper.fork_server(:callback => ['CLICK', 2])
      EM_GNTP::Client.response_class = MarshalHelper.dummy_response_class
      @subject = EM_GNTP::App.new('test', :port => DummyServerHelper::DEFAULT_PORT)
    end
    
    after do
      DummyServerHelper.kill_server(@p_svr)
    end    
    
    it 'should receive ok and CLICK callback matching multiple routes' do
      ok_count = 0
      cb_count = 0
      
      app = @subject
      app.register do
        notification 'Foo' do |n|
          n.callback 'You', :type => 'shiny'
        end
      end
     
      app.when_click 'You' do |resp|
        cb_count.must_equal 1
        cb_count += 1
      end
      
      app.when_click :context => 'You', :type => 'shiny' do |resp|
        cb_count.must_equal 0
        cb_count += 1
      end
      
      app.when_click do |resp|
        cb_count.must_equal 3
        cb_count += 1
      end
      
      app.when_click :type => 'shiny' do |resp|
        cb_count.must_equal 2
        cb_count += 1
      end
      
      app.notify('Foo') do |resp|
        ok_count += 1 if resp[0].to_i == 0
        resp[0].to_i.must_equal 0
      end

      ok_count.must_equal 1
      cb_count.must_equal 4
    end

    
end