module Groem
  
  module Constants

    def self.included(mod)
      self.constants.each do |c|
        mod.const_set(c.to_s, self.const_get(c.to_s))
      end
    end
    
    def growlify_key(str)
      parts = str.to_s.tr('_','-').split('-')
      parts.map {|p| p[0..0].upcase + p[1..-1]}.join('-')
    end
    
    def growlify_action(str)
      act = str.to_s.upcase
      act = {'CLICK' => GNTP_CLICK_CALLBACK_RESULT,
             'CLICKED' => GNTP_CLICK_CALLBACK_RESULT,
             'CLOSE' => GNTP_CLOSE_CALLBACK_RESULT,
             'CLOSED' => GNTP_CLOSE_CALLBACK_RESULT,
             'TIMEOUT' => GNTP_TIMEDOUT_CALLBACK_RESULT,
             'TIMEDOUT' => GNTP_TIMEDOUT_CALLBACK_RESULT
            }[act]
    end
     
    ENVIRONMENT_KEY = 'environment'
    HEADERS_KEY = 'headers'
    NOTIFICATIONS_KEY = 'notifications'
    
    GNTP_PROTOCOL_KEY = 'protocol'
    GNTP_VERSION_KEY = 'version'
    GNTP_REQUEST_METHOD_KEY = 'request_method'
    GNTP_ENCRYPTION_ID_KEY = 'encryption_id'
    
    GNTP_REGISTER_METHOD = 'REGISTER'
    GNTP_NOTIFY_METHOD = 'NOTIFY'
    GNTP_SUBSCRIBE_METHOD = 'SUBSCRIBE'
      
    GNTP_DEFAULT_ENVIRONMENT = {GNTP_PROTOCOL_KEY => 'GNTP',
                                GNTP_VERSION_KEY => '1.0',
                                GNTP_REQUEST_METHOD_KEY => 'NOTIFY',
                                GNTP_ENCRYPTION_ID_KEY => 'NONE'
                               }
    
    GNTP_APPLICATION_NAME_KEY = 'Application-Name'
    GNTP_APPLICATION_ICON_KEY = 'Application-Icon'
    GNTP_NOTIFICATION_COUNT_KEY = 'Notifications-Count'
    GNTP_NOTIFICATION_NAME_KEY = 'Notification-Name'
    GNTP_NOTIFICATION_ICON_KEY = 'Notification-Icon'
    GNTP_NOTIFICATION_ID_KEY  = 'Notification-ID'
    GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY = 'Notification-Callback-Context'
    GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY = 'Notification-Callback-Context-Type'
    GNTP_NOTIFICATION_CALLBACK_TARGET_KEY = 'Notification-Callback-Target'
    
    GNTP_RESPONSE_METHOD_KEY = 'response_method'
    GNTP_RESPONSE_ACTION_KEY = 'Response-Action'
    GNTP_ERROR_CODE_KEY = 'Error-Code'
    GNTP_NOTIFICATION_CALLBACK_RESULT_KEY = 'Notification-Callback-Result'
    GNTP_NOTIFICATION_CALLBACK_TIMESTAMP_KEY = 'Notification-Callback-Timestamp'
    
    GNTP_OK_RESPONSE = '-OK'
    GNTP_ERROR_RESPONSE = '-ERROR'
    GNTP_CALLBACK_RESPONSE = '-CALLBACK'
  
    GNTP_ERROR_CODE_OK = '0'
 
    GNTP_CLICK_CALLBACK_RESULT = 'CLICK'
    GNTP_CLOSE_CALLBACK_RESULT = 'CLOSE'
    GNTP_TIMEDOUT_CALLBACK_RESULT = 'TIMEDOUT'
    
  end

end