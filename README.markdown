## em-gntp
### An Eventmachine-based Growl Notification Transport Protocol (GNTP) client 

#### Examples of usage:

- **Registration**

    app = GNTP::App.new('MyApp', :host => 'localhost')
    
    app.register do
      icon 'http://www.example.com'

      notification 'started', 'Your thing has started!' do |n|
        n.header 'Data-Filename'
        n.icon 'path/to/local/file.png'   #=> generates x-growl-resource
        n.sticky
        n.callback 'process', :type => 'confirm'
      end
      
      notification 'finished', :enabled => true
      
      header 'X-Custom-Header', 'default value'
    end

- **Callbacks**
    
    app.callbacks do
    
      when_closed 'started' do |response|
        # do something with closed responses to 'started' notifications
      end
      
      when_clicked '*/process/confirm' do |response|
        # do something with click responses to all 'process' contexts of type 'confirm'
      end
      
      when_timeout do |response|  
        # do something with any timeout response regardless of context
      end
    
    end 
 
- **Notification**
    
    resp =  app.notify('started', 'XYZ has started!')
    
    
