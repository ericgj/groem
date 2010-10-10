## em-gntp
### An Eventmachine-based 
### Growl Notification Transport Protocol (GNTP) client 

#### Examples of usage:

- **Registration**

    app = GNTP::App.new('MyApp', :host => 'localhost')
    
    app.register do
      icon 'http://www.example.com/icon.png'
      header 'X-Custom-Header', 'default value'

      # notification with callback expected
      notification :started, 'Your thing has started!' do |n|
        n.header 'Data-Filename'
        n.icon 'path/to/local/file.png'   #=> generates x-growl-resource
        n.sticky
        n.callback 'process', :type => 'confirm'
      end
      
      # notification with no callback
      notification :finished, :enabled => true
      
    end

- **Notification**
    
    #  trigger notify and callbacks
    app.notify(:started, 'XYZ has started!')
    
    # trigger notify with 'ad-hoc' callback
    # -- with different settings than defined in app.register
    app.notify(:finished, 'ABC has finished!', 
               :callback => {:type => 'ad-hoc', 
                             :target => 'www.my-callback-url.com'}
              )
              
    #  trigger notify and handle responses
    app.notify(:finished, 'ABC has finished!') do |response|
      response.ok? { # handle OK response }
      response.error?  { # handle any ERROR response }
      response.error?(400) { # handle ERROR 400 (not authorized) response }
    end

    # you could also do this outside of the block
    response = app.notify(:finished, 'ABC has finished!') 
    response.ok? { # handle OK response }
    response.error?  { # handle any ERROR response }
    response.error?(400) { # handle ERROR 400 (not authorized) response }
    
    
- **Callbacks**

    app.when_close 'process' do |response|
      # do something with close responses to process notifications
    end
      
    app.when_click :context => 'process', :type => 'confirm' do |response|
      # do something with click responses that have 'process' contexts of type 'confirm'
    end
      
    app.when_click :type => 'integer' do |response|
      # do something with click responses that have type 'integer' regardless of context
    end
      
    app.when_timedout do |response|  
      # do something with any timeout response regardless of context or type
    end

    
