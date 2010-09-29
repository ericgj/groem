require 'eventmachine'

module EM_GNTP
  class Client < EM::Connection
  
    DEFAULT_HOST = 'localhost'
    DEFAULT_PORT = 23053
    
    class << self
      def response_class
        @response_class ||= EM_GNTP::Response
      end
      
      def load_response_as(klass)
        @response_class = klass
      end
      
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
      @req_action = req['environment']['request_action'] 
      cb_context = req['headers']['notification_callback_context']
      cb_context_type = req['headers']['notification_callback_context_type']
      cb_target = req['headers']['notification_callback_target']
      @wait_for_callback = @req_action == 'NOTIFY' &&
                           cb_context && cb_context_type && !cb_target
    end
    
    def post_init
      reset_state
      send_data @req.dump
    end
    
    def receive_data data
      @buffer.extract(data).each do |message|
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
      end
      close_connection_after_writing unless waiting_for_callback?
    end


    protected

    def reset_state
      @buffer = BufferedTokenizer.new("\r\n\r\n")
      @state = :init
    end
    
    def update_state_from_response!(hash)
      @state = \
        case hash['environment']['response_action']
        when '-OK'
          :ok
        when '-ERROR'
          :error
        when '-CALLBACK'
          :callback
        else  
          :unknown
        end
    end
    
    def waiting_for_callback?
      @wait_for_callback && [:ok, :init].include?(@state)
    end
    
  end
  
end