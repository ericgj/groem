require 'eventmachine'

module EM_GNTP
  class Client < EM::Connection
    include EM_GNTP::Constants
    
    DEFAULT_HOST = 'localhost'
    DEFAULT_PORT = 23053
    
    class << self
      def response_class
        @response_class ||= EM_GNTP::Response
      end
      
      def response_class=(klass)
        @response_class = klass
      end
      alias_method :load_response_as, :response_class=
      
      def request(request, host = DEFAULT_HOST, port = DEFAULT_PORT)
        connection = EM.connect host, port, self, request
        connection
      end
      alias_method :register, :request
      alias_method :notify, :request
    end
      
    def response_class
      self.class.response_class
    end
    
    def each_ok_response(&blk)
      @cb_each_response = blk
    end
    
    def each_callback_response(&blk)
      @cb_each_callback = blk
    end
    
    def each_error_response(&blk)
      @cb_each_errback = blk
    end
    
    def initialize(req)
      super
      @req = req
      @req_action = req[ENVIRONMENT_KEY][underscorize(GNTP_REQUEST_METHOD_KEY)] 
      cb_context = req[HEADERS_KEY][underscorize(GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY)]
      cb_context_type = req[HEADERS_KEY][underscorize(GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY)]
      cb_target = req[HEADERS_KEY][underscorize(GNTP_NOTIFICATION_CALLBACK_TARGET_KEY)]
      @wait_for_callback = @req_action == GNTP_NOTIFY_METHOD &&
                           cb_context && cb_context_type && !cb_target
    end
    
    def post_init
      reset_state
      send_data @req.dump
    end
    
    def receive_data data
      @buffer.extract(data).each do |line|
        @lines << line
        receive_message @lines.join("\r\n") if eof?
      end
    end


    protected

    def reset_state
      @buffer = BufferedTokenizer.new("\r\n")
      @lines = []
      @state = :init
    end
    
    def eof?
      @lines.last == ''
    end
    
    def receive_message(message)
      raw = response_class.load(message, nil)
      update_state_from_response!(raw)
      resp = response_class.new(raw)
      case @state
      when :ok
        @cb_each_response.call(resp) if @cb_each_response
      when :callback
        @cb_each_callback.call(resp) if @cb_each_callback
      when :error, :unknown
        @cb_each_errback.call(resp) if @cb_each_errback
      end
      close_connection_after_writing unless waiting_for_callback?
    end
      
    def update_state_from_response!(resp)
      @state = \
        case resp[0].to_i
        when 0
          if resp[2]
            :callback
          else
            :ok
          end
        when 100..500
          :error
        else  
          :unknown
        end
    end
    
    def waiting_for_callback?
      @wait_for_callback && [:ok, :init].include?(@state)
    end
    
  end
  
end