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
end
