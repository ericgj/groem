require 'eventmachine'

module EM_GNTP
  class Client < EM::Connection
    include EM_GNTP::Constants
    include EM::Deferrable

    DEFAULT_HOST = 'localhost'
    DEFAULT_PORT = 23053
    
    class << self
      def response_class
        @response_class ||= anonymous_response_class 
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
      
      def anonymous_response_class
        @klass_resp ||= \
          Class.new { 
            include(EM_GNTP::Marshal::Response) 
            require 'forwardable'
            extend Forwardable
            def_delegators :@raw, :[], :[]=
            def raw; @raw ||= {}; end
            def initialize(input = {})
              @raw = input
            end
          }
      end
      
      def anonymous_request_class
        @klass_req ||= \
          Class.new { 
            include(EM_GNTP::Marshal::Request) 
            require 'forwardable'
            extend Forwardable
            def_delegators :@raw, :[], :[]=
            def raw; @raw ||= {}; end
            def initialize(input = {})
              @raw = input
            end
          }
      end
      
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
      @req_action = req[ENVIRONMENT_KEY][(GNTP_REQUEST_METHOD_KEY)] 
      cb_context = req[HEADERS_KEY][(GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY)]
      cb_context_type = req[HEADERS_KEY][(GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY)]
      cb_target = req[HEADERS_KEY][(GNTP_NOTIFICATION_CALLBACK_TARGET_KEY)]
      @wait_for_callback = @req_action == GNTP_NOTIFY_METHOD &&
                           cb_context && cb_context_type && !cb_target
    end
    
    def post_init
      reset_state
      send_data @req.dump
    end
    
    def receive_data data
      @buffer.extract(data).each do |line|
        #print "#{line.inspect}"
        @lines << line
      end
      receive_message @lines.join("\r\n") + "\r\n" if eof?
    end

    protected

    def reset_state
      @buffer = BufferedTokenizer.new("\r\n")
      @lines = []
      @state = :init
    end
    
    def eof?
      @lines[-1] == ''
    end
    
    def receive_message(message)
      raw = response_class.load(message, nil)
      update_state_from_response!(raw)
      puts "Client received message, state = #{@state}"
      resp = response_class.new(raw)
      case @state
      when :ok
        @cb_each_response.call(resp) if @cb_each_response
        self.succeed(resp) unless waiting_for_callback?
      when :callback
        @cb_each_callback.call(resp) if @cb_each_callback
        self.succeed(resp)
      when :error, :unknown
        @cb_each_errback.call(resp) if @cb_each_errback
        self.fail(resp)
      end
      puts "Waiting for callback? #{waiting_for_callback? ? 'yes' : 'no'}"
      close_connection_after_writing unless waiting_for_callback?
    end
      
    def update_state_from_response!(resp)
      @state = \
        case resp[0].to_i
        when 0
          if resp[2][GNTP_NOTIFICATION_CALLBACK_RESULT_KEY]
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