require 'http/headers'
require 'http/status'
require 'stringio'

module Http
  #
  # Response encapsulates an HTTP Response in a very simiplistic 
  # manner. 
  #
  # It may also be bound to a ResponseParser and can be populated by parsing an
  # HTTP Response
  #
  class Response

    # Status code
    attr_accessor :status_code

    # Headers hash-like object
    attr_reader   :headers

    # The HTTP Protocol version of this response
    attr_accessor :protocol_version

    # The actual content length of the response, that is, the number of bytes
    # read from the body, not the value of a content-length header.  If you
    # want that, the look at headers['Content-Length'].
    attr_accessor :content_length

    # The body of the message, this is an IO like object that is at the
    # beginning of the response body
    attr_accessor :body

    def initialize
      # obtain these from the parser at on_headers_complete
      @headers = nil
      @status_code = nil
      @keep_alive = nil
      @protocol_version = nil
      @chunked_encoding = nil
     
      # these will have good values after on_message_complete 
      @content_length = nil
      @body = nil

      # internal state items used during parsing
      @header_state = nil
      @header_token = nil
      @header_fields_values = nil

    end

    def chunked_encoding?
      @chunked_encoding
    end

    def keep_alive?
      @keep_alive
    end

    # call-seq:
    #   response.status_line -> String
    #
    # The top line of an HTTP Response, 
    #
    #   HTTP-Version Status-Code Reason-Phrase CRLF
    # 
    def status_line
      "HTTP/#{protocol_version} #{status_code} #{Status.reason_for( status_code )}\r\n"
    end

    #------------------------------------------------------------------
    # Implementation of ResponseParser callbacks
    #------------------------------------------------------------------
    def on_message_begin( parser )
      @header_fields_values = []
      @header_state         = :field
      @header_token         = StringIO.new
      @content_length       = 0
      @body                 = StringIO.new
    end

    #
    # Accumulate header fields, being careful of the state transition between
    # header fields and values so as not to inadvertently merge a field and a
    # value.
    #
    def on_header_field( parser, data )
      case @header_state
      when :field
        append_header_token( data )
      when :value
        rotate_header_token( data )
        @header_state = :field
      else
        raise Error, "Invalid state for parsing header fields"
      end
    end

    #
    # Accumulate header values, being careful of the state transition between
    # header fields and values so as not to inadvertently merge a field and a
    # value.
    #
    def on_header_value( parser, data )
      case @header_state
      when :value
        append_header_token( data )
      when :field
        rotate_header_token( data )
        @header_state = :value
      else
        raise Error, "Invalid state for parsing header values"
      end
    end

    #
    # When all the headers are done, create the Headers instance and pull out
    # the other items of useful information from the parser
    #
    def on_headers_complete( parser )
      rotate_header_token
      @headers          = Headers[ *@header_fields_values ]
      @protocol_version = parser.version
      @status_code      = parser.status_code
      @keep_alive       = parser.keep_alive?
      @chunked_encoding = parser.chunked_encoding?
    end

    #
    # parse all the body data
    #
    def on_body( parser, data )
      @body ||= StringIO.new
      @content_length ||= 0

      @content_length += @body.write( data )
    end

    #
    # When the message is done, be nice and unbind from the parser
    #
    def on_message_complete( parser )
      parser.unbind_callbacks
    end

    #########
    private
    #########
  
    # update the header token with more data
    def append_header_token( data )
      @header_token.write( data )
    end

    # dump the current header toke into the fields values and start a new one
    # with the given data
    def rotate_header_token( data = nil )
      @header_fields_values << @header_token.string.dup
      @header_token.rewind
      @header_token.truncate( 0 )
      append_header_token( data.dup ) if data
    end
  end
end
