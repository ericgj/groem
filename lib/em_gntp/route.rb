
module EM_GNTP
  class Route

    class << self
      def parse action, *path
        [action] + Array.new(2).fill {|i| path[i] }
      end
    
      def matches? pattern, parts
        parts = [parts] unless Array === parts
        pattern.zip(parts).all? do |exp, act|
          exp.nil? || exp == act
        end
      end
      
    end
    
    attr_reader :pattern
    
    def initialize action, *path
      path = path.flatten
      @pattern = self.class.parse action, *path
    end
      
    def matches?(*args)
      self.class.matches?(pattern, args.flatten)
    end
        

    # sort nil parts after named parts (unless named parts begin with ~)
    def <=>(other)
      pattern.map {|it| it || '~'} <=> other.pattern.map {|it| it || '~'}
    end
    
  end
end