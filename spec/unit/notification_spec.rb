require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::Notification #[]' do

  describe 'after initializing' do
    it 'should set the notification_name header based on input' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject['headers']['Notification-Name'].must_equal 'verb'
    end
 
    it 'should not set the notification_title header if none passed' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject['headers'].keys.wont_include 'Notification-Title'
    end
  
    it 'should set the notification_title header based on input' do
      @subject = EM_GNTP::Notification.new('verb', 'title')
      @subject['headers']['Notification-Title'].must_equal 'title'
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
      @subject['headers']['Notification-Title'].must_equal 'what'
      @subject['headers']['Notification-Text'].must_equal 'False'
      @subject['headers']['Notification-Sticky'].must_equal 'True'
      @subject['headers'].keys.wont_include 'environment'
      @subject['headers'].keys.wont_include 'Notification-Environment'
    end
    
    it 'should set application_name option in headers hash' do
      opts = {:environment => {}, 
               :application_name => 'Obama'
              }
      @subject = EM_GNTP::Notification.new('verb', opts)
      @subject['headers']['Application-Name'].must_equal 'Obama'
      @subject['headers'].keys.wont_include 'Notification-Application-Name'
    end
    
    it 'should set automatic notification_id in headers hash' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject['headers'].keys.must_include 'Notification-ID'
    end
    
    it 'should set any unknown options in headers hash not prefixed by \'notification_\'' do
      opts = {:boo => 'bear', :sister_of_goldilocks => 'Reba'}
      @subject = EM_GNTP::Notification.new('verb', opts)
      @subject['headers']['Boo'].must_equal 'bear'
      @subject['headers']['Sister-Of-Goldilocks'].must_equal 'Reba'
      @subject['headers'].keys.wont_include 'Notification-Boo'
      @subject['headers'].keys.wont_include 'Notification-Sister-Of-Goldilocks'
    end
    
  end

  describe 'after setting header' do
  
    it 'should add the header to the headers hash based on input' do
      @subject = EM_GNTP::Notification.new('verb')
      @subject.header('x_header', 'boo')
      @subject['headers']['X-Header'].must_equal 'boo'
    end
  
  end
  
  describe 'after setting callback' do
  
    before do
      @subject = EM_GNTP::Notification.new('verb')
    end
    
    it 'should add the notification_callback_context header to the headers hash' do
      @subject.callback 'success'
      @subject['headers']['Notification-Callback-Context'].must_equal 'success'
    end
  
    it 'should add the notification_callback_context_type header to the headers hash, when :type passed as an option' do
      @subject.callback 'success', :type => 'test'
      @subject['headers']['Notification-Callback-Context-Type'].must_equal 'test'
    end

    it 'should add the notification_callback_target header to the headers hash, when :target passed as an option' do
      @subject.callback 'success', :target => '10.10.0.2'
      @subject['headers']['Notification-Callback-Target'].must_equal '10.10.0.2'
    end

    it 'should set the notification_callback_context and _type to the notification name, when no argments passed' do
      @subject.callback
      @subject['headers']['Notification-Callback-Context'].must_equal @subject.name
      @subject['headers']['Notification-Callback-Context-Type'].must_equal @subject.name
    end
    
  end
  
  describe 'after reset!' do
  
    it 'should not set the same notification_id' do
      @subject = EM_GNTP::Notification.new('verb')
      id = @subject['headers']['Notification_ID']
      @subject.reset!
      @subject['headers']['Notification-ID'].wont_equal id
    end
    
  end
    
end

describe 'EM_GNTP::Notification #dup' do

  before do
  
    @input_opts = { :environment => {'protocol' => 'GNTP', 
                             'version' => '2.0',
                             'request_method' => 'NOTIFY', 
                             'encryption_id' => 'ABC'
                            },
              :application_name => 'Foo',
              :display_name => 'Name here',
              :enabled => 'True',
              :text => 'Text here',
              :sticky => 'False',
              :priority => 'High',
              :coalescing_id => '12345'
            }
    @input_name = 'verb'
    @input_title = 'title'
    @headers = [['X-Header-Thing', 'Blackbeard'],
                ['X-Another-Thing', 'Creamcicle']]
    
    @input = EM_GNTP::Notification.new(@input_name, @input_title, @input_opts)
    @input.header @headers[0][0], @headers[0][1] 
    @input.header @headers[1][0], @headers[1][1]
    @input.callback
    @subject = @input.dup
  end
  
  it 'should have equal name' do
    @subject.name.must_equal @input.name
  end
  
  it 'should have equal title' do
    @subject.title.must_equal @input.title
  end

  it 'should have equal attributes' do
    @input.each_pair do |k, v|
      @subject.__send__(k).must_equal v
    end
  end
  
  it 'should have matching callback' do
    %w{Notification-Callback-Context
       Notification-Callback-Context-Type
       Notification-Callback-Target}.each do |key|
        @subject[key].must_equal @input[key]
      end
  end
  
  it 'should not have same name reference' do
    @subject.name.wont_be_same_as @input.name
  end
  
  it 'should not have same title reference' do
    @subject.title.wont_be_same_as @input.title
  end

  it 'should not have same reference for each attribute' do
    @input.each_pair do |k, v|
      @subject.__send__(k).wont_be_same_as v
    end
  end
  
  it 'should not have matching callback after changing' do
    @subject.callback 'ZZing', :type => 'Zam', :target => 'www.zombo.com'
    %w{Notification-Callback-Context
       Notification-Callback-Context-Type
       Notification-Callback-Target}.each do |key|
        @subject['headers'][key].wont_equal @input['headers'][key]
      end    
  end
  
end
