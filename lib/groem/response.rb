require 'forwardable'

module Groem
  class Response < Struct.new(:status,
                              :method,
                              :action,
                              :notification_id,
                              :context,
                              :context_type,
                              :callback_result,
                              :headers)
    include Groem::Marshal::Response
    extend Forwardable
    
    def_delegator :@raw, :[]
    
    def initialize(resp)
      @raw = resp
      self.status = resp[0]
      self.headers = resp[1]
      self.action = resp[1][GNTP_RESPONSE_ACTION_KEY]
      self.notification_id = resp[1][GNTP_NOTIFICATION_ID_KEY]
      self.context = resp[2][GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY]
      self.context_type = resp[2][GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY]
      # On Growl OSX, we get CLOSED/CLICKED instead of CLOSE/CLICK
      callback_result_key = resp[2][GNTP_NOTIFICATION_CALLBACK_RESULT_KEY]
      self.callback_result = growlify_action(callback_result_key)
      self.method = if self.status.to_i == 0
                      if self.callback_result
                        GNTP_CALLBACK_RESPONSE
                      else
                        GNTP_OK_RESPONSE
                      end
                    else
                      GNTP_ERROR_RESPONSE
                    end
    end
    
    def callback_route
      [self.callback_result, self.context, self.context_type]
    end
    
    def to_register? &blk
      yield_and_return_if self.action == GNTP_REGISTER_METHOD, &blk
    end
    
    def to_notify? &blk
      yield_and_return_if self.action == GNTP_NOTIFY_METHOD, &blk
    end
    
    def ok? &blk
      yield_and_return_if self.method == GNTP_OK_RESPONSE, &blk
    end
    
    def callback? &blk
      yield_and_return_if self.method == GNTP_CALLBACK_RESPONSE, &blk
    end
    
    def error?(code=nil, &blk)
      yield_and_return_if (self.method == GNTP_ERROR_RESPONSE  && \
                           code.nil? || self.status == code), &blk
    end
    
    def clicked? &blk
      yield_and_return_if self.callback_result == GNTP_CLICK_CALLBACK_RESULT, &blk
    end
    
    def closed? &blk
      yield_and_return_if self.callback_result == GNTP_CLOSE_CALLBACK_RESULT, &blk
    end
    
    def timedout? &blk
      yield_and_return_if self.callback_result == GNTP_TIMEDOUT_CALLBACK_RESULT, &blk
    end
    
    alias_method :click?, :clicked?
    alias_method :close?, :closed?
    alias_method :timeout?, :timedout?
    
    protected
    
    def yield_and_return_if(cond)
      yield if block_given? && cond
      cond
    end
    
  end
end
