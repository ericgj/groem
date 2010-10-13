require 'eventmachine'
require 'uuidtools'

module Groem

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
    include Groem::Marshal::Request
    
    DEFAULT_ENV = {'protocol' => 'GNTP', 'version' => '1.0',
                   'request_method' => 'NOTIFY', 'encryption_id' => 'NONE'
                  }
    
    def initialize(name, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      title = args.shift
      self.environment, self.headers, @callback = {}, {}, {}
      self.environment = DEFAULT_ENV.merge(opts.delete(:environment) || {})
      self.name = name.to_s if name
      self.title = title.to_s if title
      self.enabled = 'True'
      self.headers = opts.delete(:headers) || {}
      opts.each_pair do |opt, val| 
        if self.respond_to?(:"#{opt}=")   
          self.__send__ :"#{opt}=", val.to_s
        else
          header(opt, val.to_s)
        end
      end
      reset!
    end
    
    def [](key)
      to_request[key]
    end
    
    def reset!
      @to_request = nil
      self
    end
    
    def reset_callback!
      @callback = {}
    end

    def dup
      attrs = {}; self.each_pair {|k, v| attrs[k] = v.dup if v}
      n = self.class.new(self.name, attrs)
      n.callback(:context => callback_context, 
                 :type => callback_type,
                 :target => callback_target) if @callback
      n
    end
    
    def header key, value
      reset!
      self.headers[growlify_key(key)] = value
    end

    def icon(uri_or_file)
      # TODO if not uri
      reset!
      header GNTP_NOTIFICATION_ICON_KEY, uri_or_file
    end
    
    # Note defaults name and type to notification name
    def callback *args
      opts = ((Hash === args.last) ? args.pop : {})
      name = args.shift || opts[:context] || self.name
      type = opts[:type] || self.name
      target = opts[:target]
      reset!
      reset_callback!
      @callback[GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY] = name if name
      @callback[GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY] = type if type
      @callback[GNTP_NOTIFICATION_CALLBACK_TARGET_KEY] = target if target
      @callback
    end
    
    def callback_context
      @callback[GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY]
    end
    
    def callback_type
      @callback[GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY]
    end
    alias_method :callback_context_type, :callback_type
    
    def callback_target
      @callback[GNTP_NOTIFICATION_CALLBACK_TARGET_KEY]
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
      @to_request ||= \
        {'environment' => environment,
         'headers' => to_notify,
         'notifications' => {}
        }
    end
    
   protected 
    
    def unique_id
      UUIDTools::UUID.timestamp_create.to_s
    end
    
  end

end