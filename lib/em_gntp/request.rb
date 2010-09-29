
module EM_GNTP
  module Validation
    module Request
      
      DEFAULT_FAIL_MESSAGE = 'Request failed validation'
      
      def validate(hash, msg = DEFAULT_FAIL_MESSAGE)
        
        raise ArgumentError, 
              "#{DEFAULT_FAIL_MESSAGE}: No environment hash" \
          unless hash['environment']
        raise ArgumentError, 
              "#{DEFAULT_FAIL_MESSAGE}: No headers hash" \
          unless hash['headers']
        raise ArgumentError, 
              "#{DEFAULT_FAIL_MESSAGE}: No notifications hash" \
          unless hash['notifications']
        if block_given?
          raise ArgumentError, msg unless yield
        end
        true
      end
      
      def validate_presence_of_headers(hash, *args)
        args.flatten.each do |arg|
          raise ArgumentError,
                "#{DEFAULT_FAIL_MESSAGE}: Missing required header '#{arg}'" \
            if hash['headers'][arg.to_s].nil?
        end
      end
      
    end
  end
end

module EM_GNTP
  
  class RegisterRequest < Struct.new(:application_name,
                                     :application_icon)
    include EM_GNTP::Validation::Request
    include EM_GNTP::Marshal::Request
    
    def_delegator :[], :@raw
    
    def env; @raw['environment']; end
    def headers; @raw['headers']; end
    def notifications; @raw['notifications']; end
    
    def initialize(hash)
      validate hash, 'Not a REGISTER action' do
        hash['environment']['request_action'] == 'REGISTER'
      end
      each_pair {|k, v| validate_presence_of_headers hash, k}
      
      @raw = hash
      each_pair {|k, v| __send__ :"#{k}=", headers[k]}
    end
    
    
  end
end