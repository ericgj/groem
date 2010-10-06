
module MarshalHelper

  def self.dummy_request_class
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
  
  def self.dummy_response_class
    Class.new { 
      include(EM_GNTP::Marshal::Response) 
      require 'forwardable'
      extend Forwardable
      def_delegators :@raw, :[], :[]=
      def raw; @raw ||= []; end
      def initialize(input = [])
        @raw = input
      end
    }
  end
  
  def self.dummy_request(env = {}, hdrs = {}, notifs = {})
    klass = dummy_request_class
    klass.new({'environment' => env, 
               'headers' => hdrs,
               'notifications' => notifs
              })
  end
  
  
  
end