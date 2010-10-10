require 'eventmachine'
require 'uuidtools'

module EM_GNTP

  class Notification < Struct.new(:environment,
                                  :application_name,
                                  :name,
                                  :display_name,
                                  :enabled,
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
    
    def dup
      attrs = {}; self.each_pair {|k, v| attrs[k] = v.dup if v}
      ret = self.class.new(self.name, attrs)
      ret.callback(@callback) if @callback
      ret
    end
    
    def reset!
      @unique_id = nil
      self
    end
    
    def reset_callback!
      @callback = {}
    end
    
    def to_register
      %w{display_name enabled}.inject({}) do |memo, attr|
        if val = self.__send__(:"#{attr}")
          memo["Notification-#{growlify_key(attr)}"] = val
        end
        memo
      end.merge(self.headers)
    end
    
    def to_notify
      %w{name title text sticky priority coalescing_id}.inject({}) do |memo, attr|
        if val = self.__send__(:"#{attr}")
          memo["Notification-#{growlify_key(attr)}"] = val
        end
        memo
      end.merge({GNTP_APPLICATION_NAME_KEY => self.application_name}).
          merge({GNTP_NOTIFICATION_ID_KEY => unique_id}).
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
      self.headers[growlify_key(key)] = value
    end

    def icon(uri_or_file)
      # TODO if not uri
      header GNTP_NOTIFICATION_ICON_KEY, uri_or_file
    end
    
    # Note defaults name and type to notification name
    def callback *args
      opts = ((Hash === args.last) ? args.pop : {})
      name = args.shift || opts[:context] || self.name
      type = opts[:type] || self.name
      target = opts[:target]
      @callback[GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY] = name if name
      @callback[GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY] = type if type
      @callback[GNTP_NOTIFICATION_CALLBACK_TARGET_KEY] = target if target
      @callback
    end
    
   protected 
    
    def unique_id
      @unique_id ||= UUIDTools::UUID.timestamp_create.to_s
    end
    
  end

end