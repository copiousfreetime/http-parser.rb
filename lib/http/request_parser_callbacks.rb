require 'http/parser_callbacks'
module Http
  #
  # These are additional callbacks that are available from RequestParser
  # instances.
  #
  # RequestParser instances make available all the callbacks that are in
  # ParserCallbacks plus the following additional callbacks based around the
  # request URI.
  #
  # * on_path
  # * on_query_string
  # * on_uri
  # * on_fragment
  #
  # All of them are data callbacks and so receive to parameters, first the
  # parser instance itself and then the data.
  #
  module RequestParserCallbacks
    include ParserCallbacks
    #
    # call-seq:
    #   parser.on_path { |parser, path_data| ... }
    #   parser.on_path = lambda {|parser, path_data| ... }
    #
    # Called when path data is encountered by the RequestParser.  This is data
    # that is in the HTTP Request-Line after the Method and before the '?' that
    # prefixes the query parameters.
    #
    def on_path( &block )          self.on_path = block         ; end

    #
    # call-seq:
    #   parser.on_query_string {|parser, query_string_data| ... }
    #   parser.on_query_string = lambda {|parser, query_string_data| ... }
    #
    # Called when query_string data is encountered.  This is data that is in the
    # HTTP Request-Line after the Method, the path, and the '?'.  The
    # query_string data is all the data between the '?' and the '#' of the
    # fragment
    #
    def on_query_string( &block )  self.on_query_string = block ; end

    #
    # call-seq:
    #   parser.on_fragment {|parser, query_string_data| ... }
    #   parser.on_fragment = lambda {|parser, query_string_data| ... }
    #
    # Called when fragement data is encountered.  This is data that is in the
    # HTTP Request-Line after the Method, path, query_string and the '#'.
    # This is the data that is in the uri after the '#' before the whitespace
    # infront of the HTTP Verson on the Request-Line
    #
    def on_fragment( &block )      self.on_fragment = block     ; end

    #
    # call-seq:
    #   parser.on_uri {|parser, query_string_data| ... }
    #   parser.on_uri = lambda {|parser, query_string_data| ... }
    #
    # Called when uri data is encountered.  This is all the data on the
    # Request-Line after the Method and before the HTTP Version.
    #
    def on_uri( &block )           self.on_uri = block          ; end
  end
end
