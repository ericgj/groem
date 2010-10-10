require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'Groem::Route.parse' do

  it 'should parse nil path' do 
    @subject = Groem::Route.parse 'action', nil
    @subject.must_equal ['action', nil, nil]
  end

  it 'should parse empty path' do 
    @subject = Groem::Route.parse 'action', ''
    @subject.must_equal ['action', '', nil]
  end
  
  it 'should parse action and path' do
    @subject = Groem::Route.parse 'action', 'context', 'type'
    @subject.must_equal ['action', 'context', 'type']
  end
  
  it 'should parse path with less than 2 parts' do
    @subject = Groem::Route.parse 'action', 'context'
    @subject.must_equal ['action', 'context', nil]
  end
  
  it 'should parse path with greater than 2 parts' do
    @subject = Groem::Route.parse 'action', 'context', 'type', 'extra'
    @subject.must_equal ['action', 'context', 'type']
  end
  
end

describe 'Groem::Route#parse' do

  it 'should parse nil path' do 
    @subject = Groem::Route.new('action')
    @subject.pattern.must_equal ['action', nil, nil]
  end

  it 'should parse splatted path' do 
    @subject = Groem::Route.new('action', 'context', 'type')
    @subject.pattern.must_equal ['action', 'context', 'type']
  end

  it 'should parse array path' do 
    @subject = Groem::Route.new('action', ['context', 'type'])
    @subject.pattern.must_equal ['action', 'context', 'type']
  end
  
end


describe 'Groem::Route.matches?' do

  it 'should match identical pattern' do 
    @pattern = ['action', 'context', 'type']
    Groem::Route.matches?(@pattern, ['action', 'context', 'type'])
  end

  it 'should match nil part of pattern' do 
    @pattern = ['action', nil, 'type']
    Groem::Route.matches?(@pattern, ['action', 'context', 'type'])
  end

  it 'should match multiple nil parts of pattern' do 
    @pattern = [nil, nil, 'type']
    Groem::Route.matches?(@pattern, ['action', 'context', 'type'])
  end
    
end

describe 'Groem::Route#<=>' do

  it 'should sort by standard array sort if no nil parts in pattern' do
    subject = [ s1 = Groem::Route.new('action', 'c','d'),
                s2 = Groem::Route.new('bacon', 'b','c'),
                s3 = Groem::Route.new('action', 'b','c')
              ]
    subject.sort.must_equal [s3, s1, s2]
  end
  
  it 'should sort nil parts after non-nil parts in pattern' do
    subject = [ s1 = Groem::Route.new('action', 'c','d'),
                s2 = Groem::Route.new('bacon', 'b','c'),
                s3 = Groem::Route.new('action', 'b','c'),
                s4 = Groem::Route.new('action', nil,'c'),
                s5 = Groem::Route.new('action', nil,'b'),
                s6 = Groem::Route.new('action', 'c',nil)
              ]
    subject.sort.must_equal [s3, s1, s6, s5, s4, s2]
  end
  
end

