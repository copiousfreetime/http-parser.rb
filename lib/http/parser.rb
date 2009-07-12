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
    
    # if an exception is raised in a callback, then it is stored here
    attr_reader :callback_exception

    #
    # Parser should not be initialized directly, it should be done via one of
    # the child classes, RequestParser or ResponseParser.  This is here solely
    # to initialize the callback data members.
    #
    def initialize
      @on_message_begin_callback    = nil
      @on_header_field_callback     = nil
      @on_header_value_callback     = nil
      @on_headers_complete_callback = nil
      @on_body_callback             = nil
      @on_message_complete_callback = nil
      @on_error_callback            = nil

      @callback_exception           = nil
    end

    ##
    # Callbacks, the can either be invoked as a block, or be assigned directly.
    # 
    # Take for instance, the +on_header_field+ callback.  It can be assigned
    # either via a block notation, or assigned to directly as something that
    # responds to +call+.
    #
    #   parser.on_header_field do |field|
    #   ...
    #   end
    #
    # or
    #
    #   parser.on_header_field = lambda { |field| ... }
    #
    # or
    #
    #   parser.on_header_field = HeaderFieldDoSometing.new # this class responds to +call+
    #
    def on_message_begin( &block )    self.on_message_begin = block    ; end
    def on_header_field( &block )     self.on_header_field = block     ; end
    def on_header_value( &block )     self.on_header_value = block     ; end
    def on_headers_complete( &block ) self.on_headers_complete= block  ; end
    def on_body( &block )             self.on_body = block             ; end
    def on_message_complete( &block ) self.on_message_complete = block ; end

    ## 
    # on error callback, which is not part of the underlying C parser callback
    # system so it can be done in ruby
    #
    def on_error=(callable)
      @on_error_callback = callable
    end
    def on_error(&block) self.on_error = block; end

  end
end

require 'http/parser_version'
require 'http/request_parser'
#require 'http/response_parser'
