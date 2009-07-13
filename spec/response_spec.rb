require File.expand_path( File.join( File.dirname( __FILE__ ), "spec_helper.rb" ) )

require 'http/response'
require 'http/parser'

describe Http::Response do
  before( :each ) do
    @parser = Http::ResponseParser.new
    @rubyforge = IO.read( http_res_file( "200_ruby-lang" ))
    @response = Http::Response.new
  end

  it "binds a tst obj to a parser" do

  end

  it "binds to a parser" do
    @parser.bind_and_parse( @response, @rubyforge )
    @response.status_code.should == 200
    @response.protocol_version.should == "1.1"
    @response.chunked_encoding?.should == true
    @response.content_length.should == 12153
    @response.headers['Content-Type'].should == "text/html;charset=utf-8"
  end

end
