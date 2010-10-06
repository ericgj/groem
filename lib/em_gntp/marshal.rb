require 'strscan'

module EM_GNTP
  
  module Constants

    def self.included(mod)
      self.constants.each do |c|
        mod.const_set(c.to_s, self.const_get(c.to_s))
      end
    end
    
    def underscorize(key)
      key.to_s.downcase.tr('-','_')
    end
    
    def dasherize(key)
      key.to_s.tr('_','-')
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
    GNTP_NOTIFICATION_COUNT_KEY = 'Notifications-Count'
    GNTP_NOTIFICATION_NAME_KEY = 'Notification-Name'
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
 
    GNTP_CLICKED_CALLBACK_RESULT = 'CLICKED'
    GNTP_CLOSED_CALLBACK_RESULT = 'CLOSED'
    GNTP_TIMEOUT_CALLBACK_RESULT = 'TIMEOUT'
    
  end
  
  module Marshal 
    module Request
      include EM_GNTP::Constants
      
      def self.included(mod)
        mod.extend ClassMethods
      end
    
      # write GNTP request string, print lines as \r\n
      # assumes that including class delegates :[] to raw hash 
      #   (described below under load).
      # TODO: calculate UUIDs for binary sections and output them
      def dump
        out = []
        env = GNTP_DEFAULT_ENVIRONMENT.merge(self[ENVIRONMENT_KEY])
        hdrs = self[HEADERS_KEY]
        notifs = self[NOTIFICATIONS_KEY]
        
        out << "#{env[(GNTP_PROTOCOL_KEY)]}" + 
               "/#{env[(GNTP_VERSION_KEY)]} "+
               "#{env[(GNTP_REQUEST_METHOD_KEY)]} "+
               "#{env[(GNTP_ENCRYPTION_ID_KEY)]}"
        hdrs.each_pair do |k, v|
          unless v.nil?
            out << "#{(k)}: #{v}"
          end
        end
        
        if env[(GNTP_REQUEST_METHOD_KEY)] == GNTP_REGISTER_METHOD
          out << "#{GNTP_NOTIFICATION_COUNT_KEY}: #{notifs.keys.count}"
          out << nil
          notifs.each_pair do |name, pairs|
            out << "#{GNTP_NOTIFICATION_NAME_KEY}: #{name}"
            pairs.each do |pair|
              unless pair[1].nil?
                out << "#{(pair[0])}: #{pair[1]}"
              end
            end
            out << nil
          end
        end
        
        if out.last.nil?
          1.times { out << nil }
        else
          2.times { out << nil }
        end
        
        out.join("\r\n")
      end
        
           
      module ClassMethods
        include EM_GNTP::Constants
        
        #
        # Load GNTP request into hash of:
        #     'environment' => hash of environment (protocol, version, request_method, encryption data)
        #     'headers' =>  hash of headers
        #     'notifications' => hash of notifications keyed by name (REGISTER requests only, otherwise empty)
        #
        # Note that binary identifiers are resolved in both headers and notifications.
        #
        # If passed an optional klass, will return klass.new(out), otherwise just the hash.
        # By default it tries to use the including object's class
        #
        # Note entire GNTP message must be passed as input.
        #
        # No semantic validation of input is done, 
        #   and all key values are stored as strings, not casted
        #
        # Syntactic validation may be implemented in the future.
        #
        def load(input, klass = self)
          env, hdrs, notifs = {}, {}, {}
          meth, notif_name, id, len, bin = nil
          section = :init
          s = StringScanner.new(input)
          until s.eos?
            line, section = scan_line(s, meth, section)
            case section
            when :first
              parse_first_header(line, env)
              meth = env[(GNTP_REQUEST_METHOD_KEY)]
            when :headers
              parse_header(line, hdrs)
            when :notification_start
              notif_name = parse_notification_name(line)
            when :notification
              parse_notification_header(line, notif_name, notifs)
            when :identifier_start
              id = parse_identifier(line)
            when :identifier_length
              len = parse_identifier_length(line)
            when :binary
              bin = \
                (1..len).inject('') do |memo, i|
                  memo << s.getch; memo
                end
              resolve_binary_key(id, bin, hdrs)
              resolve_binary_key(id, bin, notifs)
            end
          end
          
          out = { ENVIRONMENT_KEY => env, 
                  HEADERS_KEY => hdrs, 
                  NOTIFICATIONS_KEY => notifs
                }
               
          klass ? klass.new(out) : out
        end
        
        protected
        
        def scan_line(scanner, method, state)
          line = nil
          new_state = state
          case state
          when :init
            line = scanner.scan(/.*\n/)
            new_state = :first
          when :first
            line = scanner.scan(/.*\n/)
            new_state = :headers
          when :headers
            line = scanner.scan(/.*\n/)
            new_state = if line =~ /^\w*identifier\w*:/i
                          :identifier_start 
                        elsif method == GNTP_REGISTER_METHOD && \
                              line =~ /^\s*#{GNTP_NOTIFICATION_NAME_KEY}\s*:/i
                          :notification_start
                        else
                          :headers
                        end
          when :notification_start
            line = scanner.scan(/.*\n/)
            new_state = :notification
          when :notification
            line = scanner.scan(/.*\n/)
            new_state = if line =~ /^\s*identifier\s*:/i
                          :identifier_start 
                        elsif method == GNTP_REGISTER_METHOD && \
                              line =~ /^\s*#{GNTP_NOTIFICATION_NAME_KEY}\s*:/i
                          :notification_start
                        else
                          :notification
                        end
          when :identifier_start
            line = scanner.scan(/.*\n/)
            new_state = :identifier_length if line =~ /^\s*length\s*:/i
          when :identifier_length
            new_state = :binary
          when :binary
            line = scanner.scan(/.*\n/)
            new_state = if line =~ /^\s*identifier\s*:/i
                          :identifier_start 
                        elsif method == GNTP_REGISTER_METHOD && \
                              line =~ /^\s*#{GNTP_NOTIFICATION_NAME_KEY}\s*:/i
                          :notification_start
                        else
                          :headers
                        end
          end
          puts "state #{state} --> #{new_state}"
          state = new_state
          line = line.chomp if line
          [line, state]
        end
        
        def parse_first_header(line, hash)
          return hash unless line && line.size > 0
          tokens = line.split(' ')
          proto, vers = tokens[0].split('/')
          msgtype = tokens[1]
          encrypid, ivvalue = if tokens[2]; tokens[2].split(':'); end
          keyhashid = if tokens[3]; tokens[3].split(':')[0]; end
          keyhash, salt = if tokens[3] && tokens[3].split(':')[1]
                            tokens[3].split(':')[1].split('.')
                          end
          hash[(GNTP_PROTOCOL_KEY)] = proto
          hash[(GNTP_VERSION_KEY)] = vers
          hash[(GNTP_REQUEST_METHOD_KEY)] = msgtype
          hash[(GNTP_ENCRYPTION_ID_KEY)] = encrypid
          # TODO the rest
          hash
        end
        
        def parse_header(line, hash)
          return hash unless line && line.size > 0
          key, val = line.split(':', 2).map {|t| t.strip }
          key = (key)
          hash[key] = val
          hash
        end
        
        def parse_notification_name(line)
          return nil unless line && line.size > 0
          key, val = line.split(':', 2).map {|t| t.strip }
          val if key.downcase == GNTP_NOTIFICATION_NAME_KEY.downcase      
        end
        
        def parse_notification_header(line, name, hash)
          return hash unless line && line.size > 0
          key, val = line.split(':', 2).map {|t| t.strip }
          key = (key)
          (hash[name] ||= {})[key] = val
          hash      
        end
        
        def parse_identifier(line)
          return nil unless line && line.size > 0
          key, val = line.split(':', 2).map {|t| t.strip }
          val if key.downcase == 'identifier'
        end
        
        def parse_identifier_length(line)
          return nil unless line && line.size > 0
          key, val = line.split(':', 2).map {|t| t.strip }
          val.to_i if key.downcase == 'length'
        end
        
        def resolve_binary_key(key, data, hash)
          if key && \
             pairs = hash.select do |k, v| 
                        v =~ /x-growl-resource:\/\/#{Regexp.escape(key)}/i
                     end
            pairs.each { |p| hash[p[0]] = data }
          end
          hash
        end
      
      end  # GNTP::Marshal::Request::ClassMethods
            
    end   # GNTP::Marshal::Request
  
  
    module Response
      include EM_GNTP::Constants
      
      def self.included(mod)
        mod.extend ClassMethods
      end
    
      # write GNTP request string, print lines as \r\n
      # assumes that including class delegates :[] to raw hash 
      #   (described below under load).
      def dump
        #TODO
      end
      
      module ClassMethods
        include EM_GNTP::Constants
      
        # Load GNTP response into array of:
        #     status  (error code or '0' for OK) 
        #     hash of headers  (except error code and callback result)
        #     callback result (for callback responses, otherwise nil)
        #
        # Note this is explicitly modeled after Rack's interface
        #
        def load(input, klass = self)
          env, hdrs = {}, {}
          status, meth, cb_rslt = nil
          section = :init
          s = StringScanner.new(input)
          until s.eos?
            line, section = scan_line(s, meth, section)
            case section
            when :first
              parse_first_header(line, env)
            when :headers
              parse_header(line, hdrs)
            end
          end
          
          # pull out status and callback result
          status = hdrs.delete((GNTP_ERROR_CODE_KEY))
          cb_rslt = hdrs.delete((GNTP_NOTIFICATION_CALLBACK_RESULT_KEY))
          
          # set status OK unless already set by error code and unless -ERROR response
          meth = env[(GNTP_RESPONSE_METHOD_KEY)]
          status ||= GNTP_ERROR_CODE_OK unless meth == GNTP_ERROR_RESPONSE
          
          out = [ status, hdrs, cb_rslt ]
                
          klass ? klass.new(out) : out
        end
        
        protected
        
        def scan_line(scanner, method, state)
          line = nil
          new_state = state
          case state
          when :init
            line = scanner.scan(/.*\n/)
            new_state = :first
          when :first
            line = scanner.scan(/.*\n/)
            new_state = :headers
          when :headers
            line = scanner.scan(/.*\n/)
            new_state = :headers
          end
          #puts "state #{state} --> #{new_state}"
          state = new_state
          line = line.chomp if line
          [line, state]
        end
        
        def parse_first_header(line, hash)
          return hash unless line && line.size > 0
          tokens = line.split(' ')
          proto, vers = tokens[0].split('/')
          msgtype = tokens[1]
          encrypid = tokens[2]
          hash[(GNTP_PROTOCOL_KEY)] = proto
          hash[(GNTP_VERSION_KEY)] = vers
          hash[(GNTP_RESPONSE_METHOD_KEY)] = msgtype
          hash[(GNTP_ENCRYPTION_ID_KEY)] = encrypid
          hash
        end
        
        def parse_header(line, hash)
          return hash unless line && line.size > 0
          key, val = line.split(':', 2).map {|t| t.strip }
          key = (key)
          hash[key] = val
          hash
        end        
        
      end
      
    end  # GNTP::Marshal::Response
    
    
  end   # GNTP::Marshal
  
end