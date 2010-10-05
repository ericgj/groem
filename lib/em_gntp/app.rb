require 'eventmachine'

module EM_GNTP

  class App < Struct.new(:host, :port, 
                         :environment, :headers, :notifications)
    include EM_GNTP::Marshal::Request
    
    DEFAULT_ENV = {'protocol' => 'GNTP', 'version' => '1.0',
                   'request_method' => 'REGISTER', 'encryption_id' => 'NONE'
                  }
                  
    def initialize(name, opts = {})
      opts[:environment] = DEFAULT_ENV.merge(opts[:environment])
      environment, headers, notifications = {}, {}, {}
      headers['application_name'] = name
      each do {|attr| self.__send__ :"#{attr}=", opts[attr.to_sym] }
    end
    
    def [](key)
      to_request[key]
    end
    
    def register(&blk)
      if blk.arity == 1
        blk.call(self)
      else
        instance_eval(&blk)
      end
      send_register
    end
    
    def notify(name, title = nil, opts = {}, &blk)
      n = notifications[name]
      n.reset!    # forces new notification id
      n.title = title if title
      opts.each_pair {|k, v| n.__send__ :"#{k}=", v}
      send_notify(n, &blk)      
    end
    
    def notification(name, *args, &blk)
      n = EM_GNTP::Notification.new(name, *args)
      yield(n)
      n.application_name = headers['application_name']
      notifications[name] = n
      n
    end
   
    def icon(file_or_uri)
    end
    
    def header(key, value)
      headers[key] = value
    end
    
    def binary(key, value)
    end
    
    
    def callbacks
      #TODO
    end
        
    
    def to_request
      {'environment' => environment, 
       'headers' => headers, 
       'notifications' => notifications_to_register
      }
    end
    
   protected
    
    def send_register
      if EM.reactor_running?
        EM_GNTP::Client.register(self, host, port)
      else
        EM.run {
          connect = EM_GNTP::Client.register(self, host, port)
          connect.callback { |resp| EM.stop }
          connect.errback  { |resp| EM.stop }
        }
      end
    end
    
    def send_notify(notif, &blk)
      if EM.reactor_running?
        connect = EM_GNTP::Client.notify(notif, host, port)
        connect.callback &blk
        connect.errback &blk
      else
        EM.run {
          connect = EM_GNTP::Client.notify(notif, host, port)
          connect.callback { |resp| blk.call(resp); EM.stop }
          connect.errback  { |resp| blk.call(resp); EM.stop }
        }
      end
    end
    
    def notifications_to_register
      notifications.inject({}) do |memo, pair|
        memo[pair[0]] = pair[1].to_register
        memo
      end
    end
        
    
  end
  
end