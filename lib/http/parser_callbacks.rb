module Http
  #
  # This is a container module to hold the documentation and information about
  # ParserCallbacks.  This module is included in the Http::Parser class.
  #
  # There is a single parser that is used for both Request parsing and Response
  # parsing.  The RequestParser has a few more callbacks and those are
  # documented in RequestParserCallbacks.
  #
  # There are 7 callbacks.  In the normal course of things, you should only see
  # 6 of them.
  #
  # * on_message_begin( parser )
  # * on_header_field( parser, field )
  # * on_header_value( parser, value )
  # * on_headers_complete( parser )
  # * on_body( parser, data )
  # * on_message_complete( parser )
  #
  # The callbacks come in 2 forms, data callbacks and notification callbacks.
  # The only difference is the number of parameters each is passed.  All
  # callbacks recieve the Parser as the first parameter.  
  #
  # If the callback is a data callback, then it will recieve an appropriate
  # piece of data too.  See the individual methods for details.
  #
  # The lifecyle of the callbacks is as follows
  #
  # - a single call to on_message_begin
  # - multiple calls to on_header_field and on_header_value 
  # - a single call to on_headers_complete
  # - multiple calls to on_body
  # - a single call to on_message_complete
  #
  #
  # All callbacks have 2 registration forms, the block form:
  #
  #   parser.on_body do |parser, data|
  #     # .. do something
  #   end
  #
  # And the lambda/callable form:
  #
  #   parser.on_body = lambda { |parser, data| ... }
  #
  # In the labmda / callable form, anything that <tt>respond_to?( :call )</tt>
  # may be assiged as the callback.
  #
  # The last callback is the on_error callback.
  #
  module ParserCallbacks
    #
    # call-seq:
    #   parser.on_message_begin { |parser| ... }
    #   parser.on_message_begin = lambda { |parser| ... }
    #
    # register the block/lambda/Proc as the on_message_begin callback.  This
    # callback will be invoked at the start of message parsing. 
    #
    def on_message_begin( &block )    self.on_message_begin = block    ; end
    
    #
    # call-seq:
    #   parser.on_header_field { |parser,field_data| ... }
    #   parser.on_header_field = lambda { |parser, field_data| ... }
    #
    # register the callback for the on_header_field callback.  This callback
    # will be called multiple times.  Each invocation it will be passed some
    # data that is part of a HTTP Message Header field.  It may be called
    # multiple times for the same exact header, just adding more data.
    #
    # For example, If the parser is in the middle of a header, say it has
    # processed the 'Ho' of a 'Host' header.  At that point the parsable block
    # of data it is working on has run out and it needs more data, it will
    # invoke this callback as +callback(parser,'Ho')+ and as soon as more data
    # arrives it will probably make another callback of +callback(parser,'st')+ 
    #
    def on_header_field( &block )     self.on_header_field = block     ; end

    # 
    # call-seq:
    #   parser.on_header_value { |parser, value_data| ... }
    #   parser.on_header_value = lambda { |parser, value_data| ... }
    #
    # register the callback for the on_header_value callback.  This callback
    # will be called multiple times.  Each invocation it will be passed some
    # data that is part of a HTTP Message Header field.  It may be called
    # multiple times for the same exact header, just adding more data.
    #
    # The same caveats for on_header_field applied to on_header_value
    #
    def on_header_value( &block )     self.on_header_value = block     ; end

    #
    # call-seq:
    #   parser.on_headers_complete { |parser| ... }
    #   parser.on_headers_complete = lambda { |parser| ... }
    #
    # register the callback for the on_headers_complete callback.  This is
    # a notification callback, and called only once, at the moment all headers
    # have been processed.
    #
    # This is a good callback to capture off all the data that is stored in the
    # parser, for instance the HTTP Method, the Status code and the HTTP Version
    # used in this message.
    #
    def on_headers_complete( &block ) self.on_headers_complete= block  ; end

    # 
    # call-seq:
    #   parser.on_body { |parser, body_data| ... }
    #   parser.on_body = lambda { |parser, body_data| ... }
    #
    # register the callback for the on_body_value callback.  This callback
    # will be called multiple times.  Each invocation it will be passed some
    # data that is part of the message body.  
    #
    # The parser takes care of dealing with Chunked Encoding, so you do not have
    # to.  
    #
    def on_body( &block )             self.on_body = block             ; end

    #
    # call-seq:
    #   parser.on_message_complete { |parser| ... }
    #   parser.on_message_complete = lambda { |parser| ... }
    #
    # register the callback for the on_message_complete callback.  This is
    # a notification callback, and called only once, at the moment the entire
    # HTTP Messasge have been processed.
    #
    # If you have not captured the Method or the Status code by now, you really
    # need to.  The parser resets itself internally immediatelly following this
    # call.  
    def on_message_complete( &block ) self.on_message_complete = block ; end

    #
    # call-seq:
    #   parser.on_error { |parser, data| ... }
    #   parser.on_error = lambda {|parser, data| ... }
    #
    # register the on_error callback.  This callback will be invoked anytime
    # an error happens in the parser.  The +data+ passed to the callback is the
    # chunk of text that it was parsing at the moment of failure.
    #
    # You should also check the +parser.callback_exception+ as this may contain
    # an exception that happened inside a callback.
    #
    # After recieving an on_error callback, the parser is no longer useful in
    # its current state.  It should be disposed of.
    #
    def on_error=(callable)
      @on_error_callback = callable
    end
    def on_error(&block) self.on_error = block; end

    #
    # call-seq:
    #   ParserCallbacks.callback_methods -> Array
    #
    # Return an array of strings for all the callback methods.
    #
    def callback_methods
      @callback_methods ||= %w[ on_message_begin on_header_field on_header_value
                                on_headers_complete on_body on_message_complete
                                on_error ]
    end
    #
    # call-seq:
    #   parser.bind_callbacks_to( obj )
    #
    # Bind every method of obj that has the same name as a callback to the
    # callback in the parser.
    #
    # The methods that are extracted from obj and bound to the parser are
    # returned from the +methods+ method in the Module.
    #
    def bind_callbacks_to( obj )
      callback_methods.each do |cb_name|
        if obj.respond_to?( cb_name ) then
          cb_method = obj.method( cb_name )
          self.send( "#{cb_name}=", cb_method )
        end
      end
    end

    #
    # call-seq:
    #   parser.unbind_callbacks -> nil
    #
    # Unbind all callbacks on this parser.
    #
    def unbind_callbacks
      callback_methods.each do |cb_name|
        self.send( "#{cb_name}=", nil )
      end
      nil
    end
  end
end
