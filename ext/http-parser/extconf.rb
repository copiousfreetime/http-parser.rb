require 'mkmf'
require 'rbconfig'

$CFLAGS += " -03"

subdir = RUBY_VERSION.sub(/\.\d$/,'')
create_makefile("http/parser/#{subdir}/http_parser_ext")
