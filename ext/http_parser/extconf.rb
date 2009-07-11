require 'mkmf'
require 'rbconfig'

subdir = RUBY_VERSION.sub(/\.\d$/,'')
$CFLAGS += " -O3"
create_makefile("http_parser/#{subdir}/http_parser_ext")
