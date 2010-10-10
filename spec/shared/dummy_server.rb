require 'eventmachine'

module Groem
  module Dummy
    class Server < EM::Connection
      include Groem::Constants
      
      DEFAULT_HOST = 'localhost'
      DEFAULT_PORT = 23052    # note one off to avoid port conflict
      
      DEFAULT_RESPONSES = { :register => ['-OK', 0],
                            :notify => ['-OK', 0],
                            :callback => ['CLICK', 10]
                          }
      
      class << self
        def canned_responses
          @canned_responses ||= DEFAULT_RESPONSES.dup
        end
        
        def reset_canned_responses
          @canned_responses = nil
        end
        
        def respond_to_register_with(meth, err = 0)
          canned_responses[:register] = [meth.to_s.upcase, err.to_i]
        end
        
        def respond_to_notify_with(meth, err = 0)
          canned_responses[:notify] = [meth.to_s.upcase, err.to_i]
        end
        
        def callback_with(rslt, secs)
          canned_responses[:callback] = [rslt.to_s.upcase, secs.to_i]
        end
        
        def listen(host = DEFAULT_HOST, port = DEFAULT_PORT)
          svr = EM.start_server host, port, self
          puts "SERVER: Dummy GNTP server listening on #{host}:#{port}"
          canned_responses.each_pair do |k, v|
            if k == :register || k == :notify
              puts "    #{k.to_s.upcase} responds #{v[0]} with status #{v[1]}"
            elsif k == :callback
              puts "    #{k.to_s.upcase} with result #{v[0]} after #{v[1]} secs"
            end
          end
          svr
        end
      end

      def post_init
        reset_state
      end
      
      def receive_data data
        @buffer.extract(data).each do |line|
          update_message_state!(line)
          @lines << line
        end
        receive_message @lines.join("\r\n") + "\r\n" if eof?
      end
      
      protected
      
      def reset_state
        @buffer = BufferedTokenizer.new("\r\n")
        @lines = []
        @response = nil
        @sections_left = 0
      end
      
      # Horribly kludgy but that's GNTP for you...
      def update_message_state!(line)
        if line[/^\s*Notifications-Count\s*:\s*(\d+)/i]
          @sections_left += $1.to_i
        end
        if line[/^.+:\s*x-growl-resource:/i]
          @sections_left += 1
        end
        if line.empty?
          @sections_left -= 1
        end
        #puts line
        #puts "Note: #{@sections_left} more sections"
      end
      
      def eof?
        if @lines[-1].empty? && @sections_left > 0
          puts "SERVER: CRLFCRLF received, but expecting #{@sections_left} more sections"
        end
        @lines[-1].empty? && @sections_left <= 0
      end
      
      def receive_message message
        puts "SERVER: Received message"
        klass = Class.new { include Groem::Marshal::Request }
        raw = klass.load(message, false)
        #puts "Parsed message:\n#{raw.inspect}"
        prepare_responses_for(raw)
        if @response
          send_data @response
          puts "SERVER: Sent response"
        end
      end
      
      def canned_responses; self.class.canned_responses; end
      
      def prepare_responses_for(req)
        case req['environment']['request_method']
        when 'REGISTER'
          prepare_register_response_for(req, 
                                        canned_responses[:register][0], 
                                        canned_responses[:register][1] 
                                       )
        when 'NOTIFY'
          prepare_notify_response_for(req, 
                                      canned_responses[:notify][0],
                                      canned_responses[:notify][1]
                                     )
          schedule_callback_response_for(req, 
                                        canned_responses[:callback][0],
                                        canned_responses[:callback][1]
                                       ) \
            if req['headers']['Notification-Callback-Context']
        end
      end
      
      # eventually replace with Response#dump, quick & dirty for now
      def prepare_register_response_for(req, meth, err)
        env, hdrs = req[ENVIRONMENT_KEY], req[HEADERS_KEY]
        out = []
        out << "#{env[(GNTP_PROTOCOL_KEY)]}" + 
               "/#{env[(GNTP_VERSION_KEY)]} "+
               "#{meth} "+
               "#{env[(GNTP_ENCRYPTION_ID_KEY)]}"
        out << "#{GNTP_RESPONSE_ACTION_KEY}: #{GNTP_REGISTER_METHOD}"
        if meth == GNTP_ERROR_RESPONSE
          out << "#{GNTP_ERROR_CODE_KEY}: #{err}"
          out << "Error-Description: An error occurred"
        end
        out << nil
        out << nil
        out << nil
        puts "SERVER: Prepared REGISTER response: #{meth}, #{err}"
        @response = out.join("\r\n")
      end

      def prepare_notify_response_for(req, meth, err)
        env, hdrs = req[ENVIRONMENT_KEY], req[HEADERS_KEY]
        out = []
        out << "#{env[(GNTP_PROTOCOL_KEY)]}" + 
               "/#{env[(GNTP_VERSION_KEY)]} "+
               "#{meth} "+
               "#{env[(GNTP_ENCRYPTION_ID_KEY)]}"
        out << "#{GNTP_RESPONSE_ACTION_KEY}: #{GNTP_NOTIFY_METHOD}"
        out << "#{GNTP_NOTIFICATION_ID_KEY}: #{hdrs[(GNTP_NOTIFICATION_ID_KEY)]}"
        if meth == GNTP_ERROR_RESPONSE
          out << "#{GNTP_ERROR_CODE_KEY}: #{err}"
          out << "Error-Description: An error occurred"
        end
        out << nil
        out << nil
        out << nil
        puts "SERVER: Prepared NOTIFY response: #{meth}, #{err}"
        @response = out.join("\r\n")
      end

      def schedule_callback_response_for(req, rslt, secs)
        EM.add_timer(secs) do
          msg = callback_response_for(req, rslt)
          send_data msg
          puts "SERVER: Sent CALLBACK response: #{rslt}"
        end
        puts "SERVER: Scheduled CALLBACK response in #{secs} secs: #{rslt}"
      end
      
      def callback_response_for(req, rslt)
        env, hdrs = req[ENVIRONMENT_KEY], req[HEADERS_KEY]
        out = []
        out << "#{env[(GNTP_PROTOCOL_KEY)]}" + 
               "/#{env[(GNTP_VERSION_KEY)]} "+
               "#{GNTP_CALLBACK_RESPONSE} "+
               "#{env[(GNTP_ENCRYPTION_ID_KEY)]}"
        out << "#{GNTP_APPLICATION_NAME_KEY}: #{hdrs[(GNTP_APPLICATION_NAME_KEY)]}"
        out << "#{GNTP_NOTIFICATION_ID_KEY}: #{hdrs[(GNTP_NOTIFICATION_ID_KEY)]}"
        out << "#{GNTP_NOTIFICATION_CALLBACK_RESULT_KEY}: #{rslt}"
        out << "#{GNTP_NOTIFICATION_CALLBACK_TIMESTAMP_KEY}: #{Time.now.strftime('%Y-%m-%d %H:%M:%SZ')}"
        out << "#{GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY}: #{hdrs[(GNTP_NOTIFICATION_CALLBACK_CONTEXT_KEY)]}"
        out << "#{GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY}: #{hdrs[(GNTP_NOTIFICATION_CALLBACK_CONTEXT_TYPE_KEY)]}"
        out << nil
        out << nil
        out << nil
        out.join("\r\n")
      end
      
    end
  end
end
