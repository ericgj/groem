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
    
    def initialize(notif_name, notif_title = nil, opts = {})
      environment, headers, @callback = {}, {}, {}
      environment = DEFAULT_ENV.merge(opts.delete(:environment))
      name = notif_name; title = notif_title
      each {|attr| self.__send__ :"#{attr}=", opts[attr]}
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
          memo["notification_#{attr}"] = self.__send__ :"#{attr}"
          memo
        end.merge(headers)
    end
    
    def to_notify
      @to_notify ||= \
        %w{name title text sticky priority coalescing_id}.inject({}) do |memo, attr|
          memo["notification_#{attr}"] = self.__send__ :"#{attr}"
          memo
        end.merge({'application_name' => application_name}).
            merge({'notification_id' => unique_id}).
            merge(@callback).
            merge(headers)
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
      @callback['notification_callback_context_type'] = opts[:type]
      @callback['notification_callback_target'] = opts[:target]
      @callback
    end
    
    protected 
    
    def unique_id
      UUIDTools::UUID.timestamp_create.to_s
    end
    
  end

end