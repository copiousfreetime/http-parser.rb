#--
# Copyright (c) 2009 Jeremy Hinegardner
# All rights reserved.  See LICENSE and/or COPYING for details.
#++

begin
  require "http/parser/#{RUBY_VERSION.sub(/\.\d$/,'')}/http_parser_ext"
rescue LoadError => le
  require 'http-parser/http_parser_ext' # for dev work
end

module Http
  #
  # The list of methods defined in the extension
  #
  METHODS = [ COPY, DELETE, GET, HEAD, LOCK, MKCOL, MOVE, OPTIONS, 
              POST, PROPFIND, PROPPATCH, PUT, TRACE, UNLOCK ].freeze
  #
  # see ext/http-parser/http-parser_ext.c
  #
  # A Parser should not be instantiated directly, you should instantiate a
  # RequestParser or a ResponseParser
  #
  class Parser
    class Error < StandardError; end

    #
    # Parser should not be instantiated 
    #
    def initialize
      raise Error, "Do not instantiate Parser.  Instantiate either a RequestParser or a ResponseParser."
    end
  end
end

require 'http/parser_version'
#require 'http/request_parser'
#require 'http/response_parser'
