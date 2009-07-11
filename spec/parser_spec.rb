require File.expand_path( File.join( File.dirname( __FILE__ ), "spec_helper.rb" ) )

require 'http/parser'

describe Http::Parser do
  it "cannot be instantiated" do
    lambda { Http::Parser.new }.should raise_error( Http::Parser::Error, "Do not instantiate Parser.  Instantiate either a RequestParser or a ResponseParser." )
  end
end
