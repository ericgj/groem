
module EM_GNTP
  class Route

    class << self
      def parse action, path
      end
    
      def matches? pattern, route
        act, name, ctx, typ = route
      end
      
    end
    
    def initialize action, path=nil
      @pattern = self.class.parse action, path
    end
      
    def matches?(*args)
      self.class.matches?(@pattern, args)
    end
    
    # better for this work to be done by custom Response class...
    def matches_response?(resp)
    end
    
    def <=>(other)
    end
    
  end
end