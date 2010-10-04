require 'eventmachine'

module EM_GNTP

  class App < Struct.new(:host, :port, 
                         :environment, :headers, :notifications)
  
    def initialize(name, opts = {})
      # configure App with opts
      headers['application_name'] = name
    end
    
    def register(&blk)
      if blk.arity == 1
        blk.call(self)
      else
        instance_eval(&blk)
      end
      send_register
    end
    
    def notification(name, *args, &blk)
      n = EM_GNTP::Notification.new(name, *args)
      yield(n)
      notifications[name.to_s] = n
      n
    end
   
    def icon(file_or_uri)
    end
    
    def header(key, value)
    end
    
    def binary(key, value)
    end
    
    
    def callbacks
      #TODO
    end
    
    def notify(name, desc = nil, &blk)
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
        EM_GNTP::Client.register(self.to_request, host, port)
      else
        EM.run {
          connect = EM_GNTP::Client.register(self.to_request, host, port)
          connect.callback { |resp| EM.stop }
          connect.errback  { |resp| EM.stop }
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