require File.join(File.dirname(__FILE__),'..','spec_helper')

describe 'EM_GNTP::Route.parse' do

  it 'should parse nil path' do 
    @subject = EM_GNTP::Route.parse 'action', nil
    @subject.must_equal ['action', nil, nil, nil]
  end

  it 'should parse empty path' do 
    @subject = EM_GNTP::Route.parse 'action', ''
    @subject.must_equal ['action', nil, nil, nil]
  end
  
  it 'should parse action and path' do
    @subject = EM_GNTP::Route.parse 'action', 'name/context/type'
    @subject.must_equal ['action', 'name', 'context', 'type']
  end
  
  it 'should parse * in path' do
    @subject = EM_GNTP::Route.parse 'action', 'name/*/type'
    @subject.must_equal ['action', 'name', nil, 'type']
  end
  
  it 'should parse * at start of path' do
    @subject = EM_GNTP::Route.parse 'action', '*/context/type'
    @subject.must_equal ['action', nil, 'context', 'type']
  end

  it 'should parse * at end of path' do
    @subject = EM_GNTP::Route.parse 'action', 'name/context/*'
    @subject.must_equal ['action', 'name', 'context', nil]
  end

  it 'should parse multiple *' do
    @subject = EM_GNTP::Route.parse 'action', 'name/*/*'
    @subject.must_equal ['action', 'name', nil, nil]
  end
  
  it 'should parse path with less than 3 parts' do
    @subject = EM_GNTP::Route.parse 'action', 'name/context'
    @subject.must_equal ['action', 'name', 'context', nil]
  end
  
  it 'should parse path with greater than 3 parts' do
    @subject = EM_GNTP::Route.parse 'action', 'name/context/type/extra'
    @subject.must_equal ['action', 'name', 'context', 'type']
  end
  
end

describe 'EM_GNTP::Route.matches?' do

  it 'should match identical pattern' do 
    @pattern = ['action', 'name', 'context', 'type']
    EM_GNTP::Route.matches?(@pattern, ['action', 'name', 'context', 'type'])
  end

  it 'should match nil part of pattern' do 
    @pattern = ['action', 'name', nil, 'type']
    EM_GNTP::Route.matches?(@pattern, ['action', 'name', 'context', 'type'])
  end

  it 'should match multiple nil parts of pattern' do 
    @pattern = [nil, 'name', nil, 'type']
    EM_GNTP::Route.matches?(@pattern, ['action', 'name', 'context', 'type'])
  end
    
end

describe 'EM_GNTP::Route#<=>' do

  it 'should sort by standard array sort if no nil parts in pattern' do
    subject = [ s1 = EM_GNTP::Route.new('action', 'b/c/d'),
                s2 = EM_GNTP::Route.new('bacon', 'a/b/c'),
                s3 = EM_GNTP::Route.new('action', 'a/b/c')
              ]
    subject.sort.must_equal [s3, s1, s2]
  end
  
  it 'should sort nil parts after non-nil parts in pattern' do
    subject = [ s1 = EM_GNTP::Route.new('action', 'b/c/d'),
                s2 = EM_GNTP::Route.new('bacon', 'a/b/c'),
                s3 = EM_GNTP::Route.new('action', 'a/b/c'),
                s4 = EM_GNTP::Route.new('action', '*/b/c'),
                s5 = EM_GNTP::Route.new('action', 'a/*/c'),
                s6 = EM_GNTP::Route.new('action', 'b/c/*')
              ]
    subject.sort.must_equal [s3, s5, s1, s6, s4, s2]
  end
  
end