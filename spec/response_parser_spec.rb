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
      while chunk = f.read( 16 ) do
        @parser.parse_chunk( chunk )
      end
    end
    count.should == 14
  end

  describe "Parses files" do
    http_files( "res").each do |res_file|
      it "#{File.basename(res_file)}" do
        count = 0
        @parser.on_message_complete = lambda {|p| count += 1}
        @parser.parse_chunk( IO.read( res_file ) )
        count.should == 1
      end
    end
  end

  it "knows the content length" do
    cl = nil
    @parser.on_headers_complete do |p|
      cl = p.content_length
    end
    @parser.parse_chunk( IO.read( http_res_file( "google" ) ) )
    cl.should == 219
  end

end
