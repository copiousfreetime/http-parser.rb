require 'rubygems'
require 'spec'

$:.unshift File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__),"..","ext"))

def http_files( matching )
  spec_dir = File.dirname( __FILE__)
  http_dir = File.join( spec_dir, 'http' )
  Dir.glob( "#{http_dir}/*.#{matching}.http" )
end

def http_req_file( matching )
  spec_dir = File.dirname( __FILE__)
  http_dir = File.join( spec_dir, 'http' )
  Dir.glob( "#{http_dir}/*#{matching}*.req.http" ).first
end

def http_res_file( matching )
  spec_dir = File.dirname( __FILE__)
  http_dir = File.join( spec_dir, 'http' )
  Dir.glob( "#{http_dir}/*#{matching}*.res.http" ).first
end
