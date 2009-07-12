require 'mkmf'
require 'rbconfig'

$CFLAGS += " -03"

subdir = RUBY_VERSION.sub(/\.\d$/,'')
create_makefile("http/parser/#{subdir}/http_parser_ext")

File.open( "Makefile", "a+" ) do |f|
  f.puts "# Make the parser file from the ragel file"
  f.puts "http_parser.c: http_parser.rl"
  f.puts "\tragel -s -G2 http_parser.rl -o $@"
end
