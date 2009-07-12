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

    class << Parser
      #
      # If a decendent of Parser wishes to use a certain buffer size in readin
      # chunks of data from an IO stream in order to send it to the parser, it
      # should use the value returned from this method.
      # 
      def default_buffer_size
        @buffer_size ||= 8192
      end
      #
      # Set the size of a buffer for use by decendant Parser classes if they
      # need to use buffers for some reason.
      #
      def default_buffer_size=( new_size )
        begin
          new_size = Float(new_size).to_i
        rescue => e
          raise ArgumentError, "buffer size must be a number greater than 0"
        end
        raise ArgumentError, "buffer size must be a number greater than 0" unless new_size > 0
        @buffer_size = new_size
      end
    end
    
    # if an exception is raised in a callback, then it is stored here
    attr_reader :callback_exception

    # the size of read/write buffers parses should use if they are using buffers
    attr_accessor :buffer_size

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
      @buffer_size                  = Parser.default_buffer_size
    end

    #
    # call-seq:
    #   parser.parse( io_or_string ) -> nil
    #   parser.parse( io_or_string, 4096 ) -> nil
    #
    # Parse the given input and invoke the appropriate callbacks during
    # execution.  
    #
    # The first parameter is one of:
    #
    # * an object that respond_to? :read
    # * anything else
    #
    # In the case of a readable object , the 2nd parameter can be used to set a
    # how many bytes of data to +read+ at once.  +parse+ will conintually call
    # +read+ until +read+ returns nil, and at that ponit parse will return.
    #
    # In the case of anything else, +to_s+ will be invoked upon the object and
    # the result will be parsed.
    #
    def parse( read_or_string, chunk_size = self.buffer_size )
      if read_or_string.respond_to?( :read ) then
        buffer = String.new
        while read_or_string.read( chunk_size, buffer ) do
          parse_chunk( buffer )
        end
      else
        parse_chunk( read_or_string.to_s )
      end
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
