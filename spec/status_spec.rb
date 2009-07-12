require File.expand_path( File.join( File.dirname( __FILE__ ), "spec_helper.rb" ) )

require 'http/status'

describe Http::Status do
  it "can tell if a code is a known code or not" do
    Http::Status.known_code?( 573 ).should == false
    Http::Status.known_code?( 100 ).should == true
  end

  it "has the list of all codes" do
    Http::Status.codes.length.should == 40
  end

  describe "Reason categories" do
  { 186 => :informational,
    286 => :success,
    386 => :redirection,
    486 => :client_error,
    586 => :server_error,
    999 => :unknown }.each_pair do |code, category|
      it "code #{code} is in category #{category}" do
        Http::Status.response_category( code ).should == category
      end
    end
  end

  describe "#reason_for" do
    it "returns a string Reason for a known code" do
      Http::Status.reason_for( 402 ).should == "Payment Required"
    end
    it 'returns nil for an uknown code' do
      Http::Status.reason_for( 420 ).should == nil
    end
  end

  it "knowns which codes must not have a message body " do
    c = (100..199).to_a << 204 << 304
    Http::Status.codes_with_no_body.should == Set.new( c )
  end
end
