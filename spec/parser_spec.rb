require File.expand_path( File.join( File.dirname( __FILE__ ), "spec_helper.rb" ) )

require 'http/parser'

describe Http::Parser do

  it "has a list of HTTP Methods" do
    Http::METHODS.size.should == 14
  end
  %w[ copy delete get head lock mkcol move options post propfind proppatch put trace unlock ].each do |m|
    m.upcase!
    it "should have the #{m} method" do
      Http::METHODS.include?( m ).should == true
    end
  end
end
