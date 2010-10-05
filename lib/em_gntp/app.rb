require 'eventmachine'

module EM_GNTP

  class App < Struct.new(:host, :port, 
                         :environment, :headers, :notifications)
    include EM_GNTP::Marshal::Request
    
    DEFAULT_HOST = 'localhost'
    DEFAULT_PORT = 23053
    DEFAULT_ENV = {'protocol' => 'GNTP', 'version' => '1.0',
                   'request_method' => 'REGISTER', 'encryption_id' => 'NONE'
                  }
                  
    def initialize(name, opts = {})
      self.environment, self.headers, self.notifications = {}, {}, {}
      self.environment = DEFAULT_ENV.merge(opts.delete(:environment) || {})
      self.host = opts.delete(:host) || DEFAULT_HOST
      self.port = opts.delete(:port) || DEFAULT_PORT
      self.headers['application_name'] = name
      opts.each_pair {|opt, val| self.headers[opt.to_s] = val }
    end
    
    # used by Marshal::Request#dump
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
      return unless n = self.notifications[name]
      n.reset!    # forces new notification id
      n.title = title if title
      opts.each_pair {|k, v| n.__send__ :"#{k}=", v}
      send_notify(n, &blk)      
    end
    
    def notification(name, *args, &blk)
      n = EM_GNTP::Notification.new(name, *args)
      yield(n)
      n.application_name = self.headers['application_name']
      self.notifications[name] = n
    end
   
    def callbacks &blk
      if blk.arity == 1
        blk.call(self)
      else
        instance_eval(&blk)
      end      
    end
        
    def header(key, value)
      self.headers[key] = value
    end
    
    def icon(file_or_uri)
      #TODO
    end
    
    def binary(key, value_or_io)
      #TODO
    end
    
    #---- callback definition methods
    
    def when_register &blk
      @register_callback = blk
    end
    
    def when_register_failed &blk 
      @register_errback = blk
    end
    
    def when_clicked path=nil, &blk
      when_notify GNTP_CLICKED_CALLBACK_RESULT, path, &blk
    end
    
    def when_closed path=nil, &blk
      when_notify GNTP_CLOSED_CALLBACK_RESULT, path, &blk
    end
    
    def when_timeout path=nil, &blk
      when_notify GNTP_TIMEOUT_CALLBACK_RESULT, path, &blk
    end
    
    def when_notify action, path=nil, &blk
      @notify_callbacks[EM_GNTP::Route.new(action, path)] = blk
    end
    
        
    def to_request
      {'environment' => self.environment, 
       'headers' => self.headers, 
       'notifications' => notifications_to_register
      }
    end
    
   protected
    
    def register_callback; @register_callback; end
    def register_errback; @register_errback || register_callback; end
    
    def send_register
      EM_GNTP::Client.response_class = EM_GNTP::Response
      if EM.reactor_running?
        connect = EM_GNTP::Client.register(self, host, port)
        connect.callback &:register_callback if register_callback
        connect.errback &:register_errback if register_errback
      else
        EM.run {
          connect = EM_GNTP::Client.register(self, host, port)
          connect.callback do |resp| 
            register_callback.call(resp) if register_callback
            EM.stop
          end
          connect.errback do |resp| 
            register_errback.call(resp) if register_errback
            EM.stop
          end
        }
      end
    end
    
    def send_notify(notif, &blk)
      EM_GNTP::Client.response_class = EM_GNTP::Response
      if EM.reactor_running?
        connect = EM_GNTP::Client.notify(notif, host, port)
        connect.callback &blk
        connect.errback &blk
        connect.each_callback_response do |resp|
          route_response(resp)
        end
      else
        EM.run {
          connect = EM_GNTP::Client.notify(notif, host, port)
          connect.callback { |resp| blk.call(resp); EM.stop }
          connect.errback  { |resp| blk.call(resp); EM.stop }
          connect.each_callback_response do |resp|
            route_response(resp)
          end
        }
      end
    end
    
    def notifications_to_register
      self.notifications.inject({}) do |memo, pair|
        memo[pair[0]] = pair[1].to_register
        memo
      end
    end
        
    def route_response(resp)
      @notify_callbacks.sort {|a, b| a[0] <=> b[0]}.each do |route, blk|
        if route.matches?(resp.callback_route)
          blk.call(resp)
        end
      end
    end
    
  end
  
end