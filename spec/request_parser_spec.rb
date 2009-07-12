require File.expand_path( File.join( File.dirname( __FILE__ ), "spec_helper.rb" ) )

require 'http/parser'

describe Http::RequestParser do
  before( :each ) do
    @parser = Http::RequestParser.new
    @firefox = IO.read( http_req_file( "firefox" ))
    @uri     = IO.read( http_req_file( "uri" ))
  end

  describe "Notification callbacks" do
    # notifiation callbacks
    %w[  on_message_begin on_headers_complete on_message_complete ].each do |cb|
      it "can set an #{cb} notification callback" do
        called = 0
        @parser.send("#{cb}=", lambda { |*args| called += 1 } )
        @parser.parse_chunk( @firefox )
        called.should == 1
      end
    end
  end

  it "knows if keep alive was used" do
    @parser.on_message_complete do |p|
      p.should be_keep_alive
    end
    @parser.parse_chunk( @firefox )
  end

  it "resets the parser automatically after on_message_complete" do
    @parser.keep_alive?.should == false
    keep_alive = nil
    @parser.on_message_complete do |p|
      keep_alive = p.keep_alive?
    end
    @parser.parse_chunk( @firefox )
    keep_alive.should == true
    @parser.keep_alive?.should == false
  end

  describe "Data callbacks" do
    before( :each ) do
      @p = Http::RequestParser.new
    end
    it "can set an 'on_header_field' callback" do
      header_fields = []
      @p.on_header_field do |p,data|
        header_fields << data.dup
      end
      @p.parse_chunk( @firefox )
      header_fields.size.should == 8
    end

    it "can set an 'on_header_value' callback" do
      header_values = []
      @p.on_header_value do |p,data|
        header_values << data.dup
      end
      @p.parse_chunk( @firefox )
      header_values.size.should == 8 
    end

    it "can set an 'on_body' callback" do
      body = nil
      @p.on_body do |p,data|
        body = data.dup
      end
      text = IO.read( http_req_file( "base" ))
      @p.parse_chunk( text )
      body.length.should == 30
    end

    it "can set an 'on_path' callback" do
      path = nil
      @p.on_path do |p, data|
        path = data.dup
      end
      @p.parse_chunk( @uri )
      path.should == "/forums/1/topics/2375"
    end

    it "can set an 'on_uri' callback" do
      uri = nil
      @p.on_uri do |p, data|
        uri = data.dup
      end
      @p.parse_chunk( @uri )
      uri.should == "/forums/1/topics/2375?page=1"
    end

    it "can set an 'on_frament' callback" do
      fragment = nil
      @p.on_fragment do |p, data|
        fragment = data.dup
      end
      @p.parse_chunk( @uri )
      fragment.should == "posts-17408"
    end
 
    it "can set an 'on_query_string' callback" do
      qs = nil
      @p.on_query_string do |p, data|
        qs = data.dup
      end
      @p.parse_chunk( @uri )
      qs.should == "page=1"
    end

    it "can raise an error in a callback" do
      @p.on_uri do |p, data|
        raise "Woops! had an error [#{data}]"
      end

      @p.on_error do |p, data|
        data.should == @uri
        p.callback_exception.should_not == nil
        p.callback_exception.message.should == "Woops! had an error [/forums/1/topics/2375?page=1]"
      end
      @p.parse_chunk( @uri )

    end

    it "raises an exception if there is an error in a callback and no on_error handler" do
      @p.on_uri do |p, data|
        raise "Woops! had an error [#{data}]"
      end
      lambda { @p.parse_chunk( @uri ) }.should raise_error( Http::Parser::Error, /Failure during parsing of chunk/)
      @p.callback_exception.message.should =~ /Woops! had an error/
    end

    it "raises an exception if there is an error in parsing" do
      lambda { @p.parse_chunk( "hello world" ) }.should raise_error( Http::Parser::Error, /Failure during parsing of chunk/ )
      @p.callback_exception.should == nil
    end
  end
end
