## Groem
### An Eventmachine-based Growl Notification Transport Protocol (GNTP) client 

For documentation of the GNTP protocol, see:
[http://www.growlforwindows.com/gfw/help/gntp.aspx](http://www.growlforwindows.com/gfw/help/gntp.aspx)

and the [Growl for Windows mailing list](http://groups.google.com/group/growl-for-windows/topics?start=).

Note this is very much beta.  The core functionality is fairly well tested, but the following features are not yet implemented:

- Binary resources (`x-growl-resource://`) in requests, including for icons
- Encryption
- Subscribe requests

See other limitations below.

## Platforms supported

Groem does not rely on any OS-specific libraries per se. It's simply an implementation of a TCP protocol.  It doesn't define any UI components, part of Growl's design is that's left to the user to decide.  But of course: you need a Growl server running that speaks GNTP... and so far as I know, to this point it's only been implemented by Growl for Windows. 

## Motivation

I wanted to be able to send desktop notifications on my Windows box from ruby running in cygwin. Call me crazy but I seem to enjoy hacking at Windows from cygwin...!  And I wanted the experience of implementing a protocol in Eventmachine. 

Groem is a spin-off of sorts from my project for the free and wonderful [Ruby Mendicant University (RMU)](http://blog.majesticseacreature.com/).


## Examples of usage

### Registration

Growl needs a 'register' request to define application options and what notifications to expect from your app.

Besides what Growl needs for registration, you can also define a **default callback** for a given notification.  This simplifies cases where *you don't care about anything except the user action* -- i.e. whether the user closed the box, clicked it, or ignored it (timed out).  Every time you send that type of notification, the same callback context, context-type and/or target URL will be used. 


      app = Groem::App.new('Downloader', :host => 'localhost')
      
      app.register do
        icon 'http://www.example.com/icon.png'
        header 'X-Custom-Header', 'default value'

        # notification with callback expected
        notification :finished, 'Your download has finished!' do |n|
          n.sticky = 'True'
          n.text = 'Run it!'
          n.icon 'path/to/local/icon.png'  #=> generate x-growl-resource (future)
          n.callback 'process', :type => 'run'
        end
        
        # notification with no callback
        notification :started, 'Your download is starting!', 
                     :display_name => 'Downloader working'
        
      end

    
### Notification
    
Notify returns the initial response from the server (whether request was OK or error).  Callbacks (the second response from the server, based on what the user did) are handled through a routing scheme, see below.

    
      #  trigger notify and callbacks
      app.notify(:started, 'XYZ has started!')
      
      # trigger notify with 'ad-hoc' callback
      # == with different settings than defined in app.register
      app.notify(:started, 'ABC has started!', 
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
    
    
### Callbacks

Callback procs allow you to capture responses from the user based on what they did (close, click, timeout), plus the two standard Growl data fields that the UI can return data in -- the context and the context-type.  

A given response will be routed to *all matching callback procs*, starting with the most specific.

(Of course, if a callback target (URL) is specified in the request, you won't get back a second response -- Growl will open up your browser instead.)


      app.when_close 'process' do |response|
        # do something with close responses to process notifications
      end
        
      app.when_click :context => 'process', :type => 'run' do |response|
        # do something with click responses that have 'process' contexts of type 'run'
      end
        
      app.when_click :type => 'integer' do |response|
        # do something with click responses that have type 'integer' regardless of context
      end
        
      app.when_timedout do |response|  
        # do something with any timeout response regardless of context or type
      end

    
## Lower-level interface

If you prefer a more direct interface you can use Groem::Client, the EM connection which Groem::App is built on.  It expects the request to be passed as a hash, and will throw OK, error, and callback responses back as a three-element array roughly modeled on Rack's interface (_status_, _headers_, and _body_ -- body in this case being a hash of GNTP callback headers).  

For instance,


    regist = {'headers' => {
                  'Application-Name' => 'SurfWriter',
                  'Application-Icon' => 'http://www.site.org/image.jpg'
                  },
               'notifications' => {
                  'Download Complete' => {
                    'Notification-Display-Name' => 'Download completed',
                    'Notification-Enabled' => 'True',
                    'X-Language' => 'English',
                    'X-Timezone' => 'PST'
                    }
                  }
              }
              
    connect = Groem::Client.register(regist)
    connect.when_ok { |resp|  # ... }
    connect.errback { |resp|  # ... }
    
    notif = {'Application-Name' => 'SurfWriter',
             'Notification-Name' => 'Download Complete',
             'Notification-ID' => some_unique_id,
             'Notification-Callback-Context' => 'myfile',
             'Notification-Callback-Context-Type' => 'confirm'
            }
    
    connect2 = Groem::Client.notify(notif)
    connect2.when_ok { |resp|  # ... }
    connect2.errback { |resp|  # ... }
    connect2.when_callback { |resp| #... }
    
    
For more details see `lib/groem/marshal`, and `spec/functional/client_spec`.


## Limitations

- No casting or uncasting of GNTP headers to or from ruby types is done -- everything is a string (or a symbol which gets converted to a string).  So the interface is a little clunky.

- If a Growl server is not running, the client's EM loop will not exit and has to be interrupted.  In the future it would be good to timeout, perhaps after several reconnect attempts.

- It has only been tested on Ruby 1.8.7 running on cygwin on WinXP.  I am planning to test on 1.9.2.


## License

Copyright (c) 2010 Eric Gjertsen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
