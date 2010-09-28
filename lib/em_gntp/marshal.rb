require 'strscan'

module EM_GNTP

  module Marshal
  
    GNTP_PROTOCOL_KEY = 'protocol'
    GNTP_VERSION_KEY = 'version'
    GNTP_MESSAGETYPE_KEY = 'message_type'
    GNTP_IS_RESPONSE_KEY = 'is_response'
  
    # load GNTP headers into array of 2 hashes:
    #     - hash of first header
    #     - hash of rest of headers
    # Note that binary identifiers are resolved.
    # if passed a klass, will return klass.new(out)
    # note entire GNTP message must be passed as input
    def load(input, klass = nil)
      out = [{}, {}]
      section = :init
      s = StringScanner.new(input)
      until s.eos?
        line = scan_line(s, section)
        case section
        when :first
          parse_first_header(line, out[0])
        when :headers
          parse_header(line, out[1])
        when :identifier
          id = parse_identifier(line)
        when :identifier_length
          len = parse_identifier_length(line)
        when :binary
          bin = \
            (1..len).inject('') do |memo, i|
              memo << s.getch; memo
            end
          resolve_binary_key(id, bin, out[1])
        end
      end
      
      klass ? klass.new(out) : out
    end
    
    # write to GNTP headers,
    # calculate UUIDs for binary sections and output them
    # do encryption (if required)
    # append \r\n\r\n
    def dump
      #TODO
    end
    
    
    protected
    
    def scan_line(scanner, state)
      line = nil
      case state
      when :init
        line = scanner.scan(/^.+$\r\n/).chomp
        state = :first
      when :first
        line = scanner.scan(/^.+$\r\n/).chomp
        state = :headers
      when :headers
        line = scanner.scan(/^.+$\r\n/).chomp
        state = :identifier if line =~ /^\w*identifier:/i
      when :identifier
        line = scanner.scan(/^.+$\r\n/).chomp
        state = :identifier_length if line =~ /^\w*length:/i
      when :identifier_length
        state = :binary
      when :binary
        line = scanner.scan(/^.+$\r\n/).chomp
        state = if line =~ /^\w*identifier:/i
                  :identifier
                else
                  :headers
                end
      end
      line
    end
    
    def parse_first_header(line, hash = {})
      return hash unless line.size > 0
      tokens = line.split(' ')
      proto, vers = tokens[0].split('/')
      msgtype = tokens[1]
      encrypid, ivvalue = if tokens[2]; tokens[2].split(':'); end
      keyhashid = if tokens[3]; tokens[3].split(':')[0]; end
      keyhash, salt = if tokens[3] && tokens[3].split(':')(1)
                        tokens[3].split(':')[1].split('.')
                      end
      hash[GNTP_PROTOCOL_KEY] = proto
      hash[GNTP_VERSION_KEY] = vers
      hash[GNTP_MESSAGETYPE_KEY] = msgtype
      hash[GNTP_IS_RESPONSE_KEY] = msgtype[0] == '-'
      # TODO the rest
      hash
    end
    
    def parse_header(line, hash)
      return hash unless line.size > 0
      key, val = line.split(':', 2).map {|t| t.strip(' ')}
      key = key.downcase.tr('-','_')
      hash[key] = val
      hash
    end
    
    def parse_identifier(line)
      return nil unless line.size > 0
      key, val = line.split(':', 2).map {|t| t.strip(' ')}
      val if key.downcase == 'identifier'
    end
    
    def parse_identifier_length(line)
      return nil unless line.size > 0
      key, val = line.split(':', 2).map {|t| t.strip(' ')}
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