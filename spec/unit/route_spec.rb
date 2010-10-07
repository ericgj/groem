require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::Route.parse' do

  it 'should parse nil path' do 
    @subject = EM_GNTP::Route.parse 'action', nil
    @subject.must_equal ['action', nil, nil]
  end

  it 'should parse empty path' do 
    @subject = EM_GNTP::Route.parse 'action', ''
    @subject.must_equal ['action', nil, nil]
  end
  
  it 'should parse action and path' do
    @subject = EM_GNTP::Route.parse 'action', 'context/type'
    @subject.must_equal ['action', 'context', 'type']
  end
  
  it 'should parse * in path' do
    @subject = EM_GNTP::Route.parse 'action', '*/type'
    @subject.must_equal ['action', nil, 'type']
  end

  it 'should parse * at end of path' do
    @subject = EM_GNTP::Route.parse 'action', 'context/*'
    @subject.must_equal ['action', 'context', nil]
  end

  it 'should parse multiple *' do
    @subject = EM_GNTP::Route.parse 'action', '*/*'
    @subject.must_equal ['action', nil, nil]
  end
  
  it 'should parse path with less than 2 parts' do
    @subject = EM_GNTP::Route.parse 'action', 'context'
    @subject.must_equal ['action', 'context', nil]
  end
  
  it 'should parse path with greater than 2 parts' do
    @subject = EM_GNTP::Route.parse 'action', 'context/type/extra'
    @subject.must_equal ['action', 'context', 'type']
  end
  
end

describe 'EM_GNTP::Route.matches?' do

  it 'should match identical pattern' do 
    @pattern = ['action', 'context', 'type']
    EM_GNTP::Route.matches?(@pattern, ['action', 'context', 'type'])
  end

  it 'should match nil part of pattern' do 
    @pattern = ['action', nil, 'type']
    EM_GNTP::Route.matches?(@pattern, ['action', 'context', 'type'])
  end

  it 'should match multiple nil parts of pattern' do 
    @pattern = [nil, nil, 'type']
    EM_GNTP::Route.matches?(@pattern, ['action', 'context', 'type'])
  end
    
end

describe 'EM_GNTP::Route#<=>' do

  it 'should sort by standard array sort if no nil parts in pattern' do
    subject = [ s1 = EM_GNTP::Route.new('action', 'c/d'),
                s2 = EM_GNTP::Route.new('bacon', 'b/c'),
                s3 = EM_GNTP::Route.new('action', 'b/c')
              ]
    subject.sort.must_equal [s3, s1, s2]
  end
  
  it 'should sort nil parts after non-nil parts in pattern' do
    subject = [ s1 = EM_GNTP::Route.new('action', 'c/d'),
                s2 = EM_GNTP::Route.new('bacon', 'b/c'),
                s3 = EM_GNTP::Route.new('action', 'b/c'),
                s4 = EM_GNTP::Route.new('action', '*/c'),
                s5 = EM_GNTP::Route.new('action', '*/b'),
                s6 = EM_GNTP::Route.new('action', 'c/*')
              ]
    subject.sort.must_equal [s3, s1, s6, s5, s4, s2]
  end
  
end