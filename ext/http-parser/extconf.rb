require 'mkmf'
require 'rbconfig'

$CFLAGS += " -O3"
subdir = RUBY_VERSION.sub(/\.\d$/,'')
create_makefile("http/parser/#{subdir}/http_parser_ext")
