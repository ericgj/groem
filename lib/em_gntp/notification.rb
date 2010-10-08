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
                                  :coalescing_id
                                 )
    include EM_GNTP::Marshal::Request
    
    DEFAULT_ENV = {'protocol' => 'GNTP', 'version' => '1.0',
                   'request_method' => 'NOTIFY', 'encryption_id' => 'NONE'
                  }
    
    def initialize(name, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      title = args.shift
      self.environment, @headers, @callback = {}, {}, {}
      self.environment = DEFAULT_ENV.merge(opts.delete(:environment) || {})
      self.name = name; self.title = title
      opts.each_pair do |opt, val| 
        if self.respond_to?(:"#{opt}=")   
          self.__send__ :"#{opt}=", val
        else
          header(opt, val)
        end
      end
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
        %w{display_name enabled icon}.inject({}) do |memo, attr|
          if val = self.__send__(:"#{attr}")
            memo["Notification-#{growlify_key(attr)}"] = val
          end
          memo
        end.merge(@headers)
    end
    
    def to_notify
      @to_notify ||= \
        %w{name title text sticky priority coalescing_id}.inject({}) do |memo, attr|
          if val = self.__send__(:"#{attr}")
            memo["Notification-#{growlify_key(attr)}"] = val
          end
          memo
        end.merge({GNTP_APPLICATION_NAME_KEY => self.application_name}).
            merge({GNTP_NOTIFICATION_ID_KEY => unique_id}).
            merge(@callback).
            merge(@headers)
    end
    
    def to_request
      {'environment' => environment,
       'headers' => to_notify,
       'notifications' => {}
      }
    end
    
    def header key, value
      @headers[growlify_key(key)] = value
    end
    
    def callback name = nil, opts = {}
      @callback[GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY] = name
      if opts[:type]
        @callback[GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY] = opts[:type]
      end
      if opts[:target]
        @callback[GNTP_NOTIFICATION_CALLBACK_TARGET_KEY] = opts[:target]
      end
      @callback
    end
    
    protected 
    
   def unique_id
      UUIDTools::UUID.timestamp_create.to_s
    end
    
  end

end