require 'strscan'

module EM_GNTP
  module Marshal 
    module Request
      
      GNTP_PROTOCOL_KEY = 'protocol'
      GNTP_VERSION_KEY = 'version'
      GNTP_REQUEST_METHOD_KEY = 'request_method'
      
      
      # load GNTP headers into array of:
      #     - hash of environment (protocol, version, request_method, encryption data)
      #     - hash of headers
      #     - hash of notifications keyed by name (REGISTER requests only, otherwise empty)
      # Note that binary identifiers are resolved in both headers and notifications.
      # if passed a klass, will return klass.new(out)
      # note entire GNTP message must be passed as input
      def load(input, klass = nil)
        env, hdrs, notifs = {}, {}, {}
        notif_name, id, len, bin = nil
        section = :init
        s = StringScanner.new(input)
        until s.eos?
          line, section = scan_line(s, section)
          case section
          when :first
            parse_first_header(line, env)
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
        
        out = [env, hdrs, notifs]
        klass ? klass.new(out) : out
      end
      
      # write to GNTP headers,
      # calculate UUIDs for binary sections and output them
      # do encryption (if required)
      # print lines as \r\n
      # append \r\n\r\n
      def dump
        #TODO
      end
      
      
      protected
      
      def scan_line(scanner, state)
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
                      elsif line =~ /^\w*notification-name\w*:/i
                        :notification_start
                      else
                        :headers
                      end
        when :notification_start
          line = scanner.scan(/.*\n/)
          new_state = :notification
        when :notification
          line = scanner.scan(/.*\n/)
          new_state = if line =~ /^\w*identifier\w*:/i
                        :identifier_start 
                      elsif line =~ /^\w*notification-name\w*:/i
                        :notification_start
                      else
                        :notification
                      end
        when :identifier_start
          line = scanner.scan(/.*\n/)
          new_state = :identifier_length if line =~ /^\w*length\w*:/i
        when :identifier_length
          new_state = :binary
        when :binary
          line = scanner.scan(/.*\n/)
          new_state = if line =~ /^\w*identifier\w*:/i
                        :identifier_start 
                      elsif line =~ /^\w*notification-name\w*:/i
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
        return hash unless line.size > 0
        tokens = line.split(' ')
        proto, vers = tokens[0].split('/')
        msgtype = tokens[1]
        encrypid, ivvalue = if tokens[2]; tokens[2].split(':'); end
        keyhashid = if tokens[3]; tokens[3].split(':')[0]; end
        keyhash, salt = if tokens[3] && tokens[3].split(':')[1]
                          tokens[3].split(':')[1].split('.')
                        end
        hash[GNTP_PROTOCOL_KEY] = proto
        hash[GNTP_VERSION_KEY] = vers
        hash[GNTP_REQUEST_METHOD_KEY] = msgtype
        # TODO the rest
        hash
      end
      
      def parse_header(line, hash)
        return hash unless line.size > 0
        key, val = line.split(':', 2).map {|t| t.strip }
        key = key.downcase.tr('-','_')
        hash[key] = val
        hash
      end
      
      def parse_notification_name(line)
        return nil unless line.size > 0
        key, val = line.split(':', 2).map {|t| t.strip }
        val if key.downcase == 'notification-name'      
      end
      
      def parse_notification_header(line, name, hash)
        return hash unless line.size > 0
        key, val = line.split(':', 2).map {|t| t.strip }
        key = key.downcase.tr('-','_')
        (hash[name] ||= {})[key] = val
        hash      
      end
      
      def parse_identifier(line)
        return nil unless line.size > 0
        key, val = line.split(':', 2).map {|t| t.strip }
        val if key.downcase == 'identifier'
      end
      
      def parse_identifier_length(line)
        return nil unless line.size > 0
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

    end
    
  end
  
end