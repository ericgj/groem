require 'forwardable'

module EM_GNTP
  class Response < Struct.new(:status,
                              :method,
                              :action,
                              :notification_name,
                              :context,
                              :context_type,
                              :callback_result,
                              :headers)
    include EM_GNTP::Marshal::Response
    extend Forwardable
    
    def_delegator :[], :@raw
    
    def initialize(resp)
      @raw = resp
      self.status = resp[0]
      self.method = if resp[0].to_i == 0
                      if resp[2]
                        GNTP_CALLBACK_RESPONSE
                      else
                        GNTP_OK_RESPONSE
                      end
                    else
                      GNTP_ERROR_RESPONSE
                    end
      self.action = resp[1][(underscorize(GNTP_RESPONSE_ACTION_KEY)]
      self.notification_name = resp[1][underscorize(GNTP_NOTIFICATION_NAME_KEY)]
      self.context = resp[1][underscorize(GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY)]
      self.context_type = resp[1][underscorize(GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY)]
      self.headers = resp[1]
      self.callback_result = resp[2]
    end
    
    def callback_route
      [self.callback_result, self.notification_name, self.context, self.context_type]
    end
    
    def to_register? ; self.action == GNTP_REGISTER_METHOD; end
    def to_notify? ; self.action == GNTP_NOTIFY_METHOD; end
    
    def ok? ; self.method == GNTP_OK_RESPONSE; end
    def error? ; self.method == GNTP_ERROR_RESPONSE; end
    def callback? ; self.method == GNTP_CALLBACK_RESPONSE; end
    
    def clicked? ; self.callback_result == GNTP_CLICKED_CALLBACK_RESULT; end
    def closed? ; self.callback_result == GNTP_CLOSED_CALLBACK_RESULT; end
    def timeout? ; self.callback_result == GNTP_TIMEOUT_CALLBACK_RESULT; end
    
  end
end
