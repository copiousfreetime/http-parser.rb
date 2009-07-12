require File.expand_path( File.join( File.dirname( __FILE__ ), "spec_helper.rb" ) )

require 'http/parser'

describe Http::Parser do

  it "has a list of HTTP Methods" do
    Http::METHODS.size.should == 14
  end

  it "can set a global default parser buffer size" do
    before = Http::Parser.default_buffer_size
    Http::Parser.default_buffer_size = 32
    after = Http::Parser.default_buffer_size
    after.should == 32
    Http::Parser.default_buffer_size = before
    Http::Parser.default_buffer_size.should == before
  end

  it "raises an exception if the global default buffer size is <= 0" do
    lambda { Http::Parser.default_buffer_size = 0 }.should raise_error( ArgumentError, 
                                                             /buffer size must be a number greater than 0/ )
  end

  it "raises an exception if the global default buffer size is not a number" do
    lambda { Http::Parser.default_buffer_size = "s" }.should raise_error( ArgumentError, 
                                                             /buffer size must be a number greater than 0/ )
  end

  %w[ copy delete get head lock mkcol move options post propfind proppatch put trace unlock ].each do |m|
    m.upcase!
    it "should have the #{m} method" do
      Http::METHODS.include?( m ).should == true
    end
  end
end
