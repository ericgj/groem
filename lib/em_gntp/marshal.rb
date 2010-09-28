require 'strscan'

module EM_GNTP

  module Marshal
  
    GNTP_PROTOCOL_KEY = 'protocol'
    GNTP_VERSION_KEY = 'version'
    GNTP_REQUEST_METHOD_KEY = 'request_method'
    GNTP_RESPONSE_METHOD_KEY = 'response_method'
    
    GNTP_ERROR_CODE_OK = 200
    GNTP_RESPONSE_METHOD_OK = '-OK'
    
    # load GNTP headers into array of:
    #     - status (integer, or nil if request)
    #     - hash of environment (protocol, version, request_method, response_method, encryption data)
    #     - hash of headers
    # Note that binary identifiers are resolved.
    # if passed a klass, will return klass.new(out)
    # note entire GNTP message must be passed as input
    def load(input, klass = nil)
      out = [nil, {}, {}]
      section = :init
      s = StringScanner.new(input)
      until s.eos?
        line = scan_line(s, section)
        case section
        when :first
          parse_first_header(line, out[1], out[0])
        when :headers
          parse_header(line, out[2], out[0])
        when :identifier
          id = parse_identifier(line)
        when :identifier_length
          len = parse_identifier_length(line)
        when :binary
          bin = \
            (1..len).inject('') do |memo, i|
              memo << s.getch; memo
            end
          resolve_binary_key(id, bin, out[2])
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
        line = scanner.scan(/^.*$\n/)
        state = :first
      when :first
        line = scanner.scan(/^.*$\n/)
        state = :headers
      when :headers
        line = scanner.scan(/^.*$\n/)
        state = :identifier if line =~ /^\w*identifier:/i
      when :identifier
        line = scanner.scan(/^.*$\n/)
        state = :identifier_length if line =~ /^\w*length:/i
      when :identifier_length
        state = :binary
      when :binary
        line = scanner.scan(/^.*$\n/)
        state = if line =~ /^\w*identifier:/i
                  :identifier
                else
                  :headers
                end
      end
      line = line.chomp if line
    end
    
    def parse_first_header(line, hash, status)
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
      hash[GNTP_REQUEST_METHOD_KEY] = msgtype unless msgtype[0] == '-'
      hash[GNTP_RESPONSE_METHOD_KEY] = msgtype if msgtype[0] == '-'
      status = GNTP_ERROR_CODE_OK if msgtype == GNTP_RESPONSE_METHOD_OK
      # TODO the rest
      hash
    end
    
    def parse_header(line, hash, status)
      return hash unless line.size > 0
      key, val = line.split(':', 2).map {|t| t.strip(' ')}
      key = key.downcase.tr('-','_')
      hash[key] = val
      status = val.to_i if key == 'error_code'
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