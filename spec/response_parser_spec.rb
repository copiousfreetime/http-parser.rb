require File.expand_path( File.join( File.dirname( __FILE__ ), "spec_helper.rb" ) )

require 'http/parser'

describe Http::ResponseParser do
  before( :each ) do
    @parser = Http::ResponseParser.new
  end

  it "can set a message_begin callback" do
    called = 0
    @parser.on_message_begin do |p|
      called += 1
    end
    @parser.parse_chunk( IO.read( http_res_file( "google" ) ) )
    called.should == 1
  end

  it "has a default buffer size" do
    @parser.buffer_size.should == 8192
  end

  it "detects the HTTP version" do 
    @parser.on_message_complete do |p|
      p.version.should == "1.1"
    end
    @parser.parse_chunk( IO.read( http_res_file( "google" ) ) )
  end

  describe "detects status code" do
    it "404" do
      @parser.on_message_complete do |p|
        p.status_code.should == 404
      end
      @parser.parse_chunk( IO.read( http_res_file( "404_headers" ) ))
    end
    it "301" do
      @parser.on_message_complete do |p|
        p.status_code.should == 301
      end
      @parser.parse_chunk( IO.read( http_res_file( "google" ) ))
    end
  end

  it "parses w/ multiple calls to parse_chunk" do
    count = 0
    @parser.on_body do |p,d|
      count += 1
    end
    File.open( http_res_file("google")) do |f|
      @parser.parse(f, 16)
    end
    count.should == 14
  end

  describe "Parses files" do
    http_files( "res").each do |res_file|
      next if res_file =~ /200_headers_0_chunked/
      it "#{File.basename(res_file)}" do
        count = 0
        @parser.on_message_complete = lambda {|p| count += 1}
        File.open( res_file ) do |f|
          @parser.parse( f, 10 )
        end
        count.should == 1
      end
    end
  end

  it "has an error on in valid chunked body" do
    lambda { @parser.parse( IO.read( http_res_file( "200_headers_0_chunked" ) ) ) }.should raise_error( Http::Parser::Error, /Failure during parsing of chunk/ )
  end

  it "knows the content length" do
    cl = nil
    @parser.on_headers_complete do |p|
      cl = p.content_length
    end
    @parser.parse_chunk( IO.read( http_res_file( "google" ) ) )
    cl.should == 219
  end

  it "knows what its callbacks are" do
    @parser.callback_methods.size.should == 7
  end


  it "can bind callbacks" do
    class C
      attr_accessor :callback_hits
      def initialize
        @callback_hits = 0
      end
      def on_message_begin(p) @callback_hits += 1; end
      def on_headers_complete(p) @callback_hits += 1; end
      def on_message_complete(p) @callback_hits += 1; end
      def on_error(p,d)
        puts "Had an error with #{p.callback_exception}"
      end
    end
    c = C.new
    @parser.bind_and_parse( c, IO.read( http_res_file( "google" ) ) )
    c.callback_hits.should == 3
  end
end
