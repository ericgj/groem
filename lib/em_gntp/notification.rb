require 'eventmachine'
require 'uuidtools'

module EM_GNTP

  class Notification < Struct.new(:environment,
                                  :application_name,
                                  :name,
                                  :display_name,
                                  :enabled,
                                  :icon,
                                  :title,
                                  :text,
                                  :sticky,
                                  :priority,
                                  :coalescing_id,
                                  :headers
                                 )
    include EM_GNTP::Marshal::Request
    
    DEFAULT_ENV = {'protocol' => 'GNTP', 'version' => '1.0',
                   'request_method' => 'NOTIFY', 'encryption_id' => 'NONE'
                  }
    
    def initialize(name, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      title = args.shift
      self.environment, self.headers, @callback = {}, {}, {}
      self.environment = DEFAULT_ENV.merge(opts.delete(:environment) || {})
      self.name = name; self.title = title
      opts.each_pair {|opt, val| self.__send__ :"#{opt}=", val}
      reset!
    end
    
    def [](key)
      to_request[key]
    end
    
    def reset!
      @to_register, @to_notify = nil, nil
      self
    end
    
    def reset_callback!
      @callback = {}
    end
    
    def to_register
      @to_register ||= \
        %w{name display_name enabled icon}.inject({}) do |memo, attr|
          if val = self.__send__(:"#{attr}")
            memo["notification_#{attr}"] = val
          end
          memo
        end.merge(self.headers)
    end
    
    def to_notify
      @to_notify ||= \
        %w{name title text sticky priority coalescing_id}.inject({}) do |memo, attr|
          if val = self.__send__(:"#{attr}")
            memo["notification_#{attr}"] = val
          end
          memo
        end.merge({'application_name' => self.application_name}).
            merge({'notification_id' => unique_id}).
            merge(@callback).
            merge(self.headers)
    end
    
    def to_request
      {'environment' => environment,
       'headers' => to_notify,
       'notifications' => {}
      }
    end
    
    def header key, value
      headers[key.to_s] = value
    end
    
    def callback name = nil, opts = {}
      @callback['notification_callback_context'] = name
      if opts[:type]
        @callback['notification_callback_context_type'] = opts[:type]
      end
      if opts[:target]
        @callback['notification_callback_target'] = opts[:target]
      end
      @callback
    end
    
    protected 
    
    def unique_id
      UUIDTools::UUID.timestamp_create.to_s
    end
    
  end

end