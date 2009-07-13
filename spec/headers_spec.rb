require File.expand_path( File.join( File.dirname( __FILE__ ), "spec_helper.rb" ) )

require 'http/headers'
require 'set'

describe Http::Headers do
  before( :each )  do
    @h = Http::Headers.new
  end

  it "#store" do
    @h['Content-Length'] = 42
    @h['content-length'].should == "42"
  end

  it "#store multiple keys" do
    @h['Warning'] = "watch it"
    @h['Warning'] = "you could hurt yourself"
    @h['Warning'].should == [ 'watch it', 'you could hurt yourself' ]
  end

  it "#keys" do
    @h['Warning'] = 'ouch'
    @h['Content-length'] = 256
    h1 = Set.new( @h.keys )
    h2 = Set.new( ['Warning', 'Content-length'] )
    h1.should == h2
  end

  it "#store keys with differing cases" do
    @h['WARNING'] = "w2"
    @h['Warning'] = "w1"
    @h.values.first.sort.should == %w[ w1 w2 ]
  end

  it "#store values under the most recently seen case sensitive key" do 
    @h['WARNING'] = "w2"
    @h['Warning'] = "w1"
    @h.keys.should == [ 'Warning' ]
  end

  it "#delete" do
    @h['Warning'] = "w1"
    @h.size.should == 1
    @h.delete( "WARNING" ).should == "w1"
    @h.size.should == 0
    @h.should be_empty
  end

  it "#fetch returns nil for non-existent keys" do
    @h['huh?'].should == nil
  end

  it "#clear" do
    @h['Warning'] = "w1"
    @h.size.should == 1
    @h.clear
    @h.size.should == 0
    @h.should be_empty
  end

  it "#to_hash" do
    @h['Warning'] = "w1"
    @h['warning'] = "w2"
    @h['Content-Length'] = 42
    @h['Host'] = "www.ruby-lang.org"
    @h.to_hash.should == {
      'warning' => %w[ w1 w2 ],
      "Content-Length" => "42",
      "Host" => "www.ruby-lang.org" }
  end

  it "#initializes with a hash" do
    i = { 'warning' => %w[ w1 w2 ], "Content-Length" => "42", "Host" => "www.ruby-lang.org",
          'Age' => 109, '_why' => nil}
    h = Http::Headers.new( i )
    h['Warning'].should == %w[ w1 w2 ]
    h['content-length'].should == "42"
    h[:host].should == "www.ruby-lang.org"
    h['age'].should == "109"
    h['_Why'].should == nil
    h.keys.include?( "_why" ).should == true
  end

  it "Can be created from an array of strings" do
    a = [ "Date", "Sun, 12 Jul 2009 19:08:18 GMT",
          "Server",  "Apache/2.2.3 (Debian) DAV/2 SVN/1.4.2 mod_ruby/1.2.6 Ruby/1.8.5(2006-08-25) mod_ssl/2.2.3 OpenSSL/0.9.8c",
          "Transfer-Encoding",  "chunked",
          "Content-Type",  "text/html;charset=utf-8"]
    h = Http::Headers[ *a ]
    (0...a.size).step(2) do |i|
      h[a[i]].should == a[i+1]
    end
  end
end
