
module EM_GNTP
  class Route

    class << self
      def parse action, path
        parts = path.split('/')[0..2].map {|p| p == '*' ? nil : p}
        [action] + Array.new(3).fill {|i| parts[i] }
      end
    
      def matches? pattern, parts
        parts = [parts] unless Array === parts
        pattern.zip(parts).all? do |exp, act|
          exp.nil? || exp == act
        end
      end
      
    end
    
    def initialize action, path=nil
      @pattern = self.class.parse action, path
    end
      
    def matches?(*args)
      self.class.matches?(@pattern, args)
    end
        
    def <=>(other)
    end
    
  end
end