module Http
  # 
  # Encapsulating all the known status codes, their reasons  and 
  # some common operations around them.
  #
  class Status
    class << self
      
      # 
      # call-seq:
      #   Status.reason_map -> Hash
      #
      # The hash of every standard HTTP status code and its associated human
      # readable reason phrase. 
      # 
      # Taken from Mongrel and Rack.
      #
      def reason_map 
        @map ||=  {
          100  => 'Continue',
          101  => 'Switching Protocols',
          200  => 'OK',
          201  => 'Created',
          202  => 'Accepted',
          203  => 'Non-Authoritative Information',
          204  => 'No Content',
          205  => 'Reset Content',
          206  => 'Partial Content',
          300  => 'Multiple Choices',
          301  => 'Moved Permanently',
          302  => 'Found',
          303  => 'See Other',
          304  => 'Not Modified',
          305  => 'Use Proxy',
          307  => 'Temporary Redirect',
          400  => 'Bad Request',
          401  => 'Unauthorized',
          402  => 'Payment Required',
          403  => 'Forbidden',
          404  => 'Not Found',
          405  => 'Method Not Allowed',
          406  => 'Not Acceptable',
          407  => 'Proxy Authentication Required',
          408  => 'Request Timeout',
          409  => 'Conflict',
          410  => 'Gone',
          411  => 'Length Required',
          412  => 'Precondition Failed',
          413  => 'Request Entity Too Large',
          414  => 'Request-URI Too Large',
          415  => 'Unsupported Media Type',
          416  => 'Requested Range Not Satisfiable',
          417  => 'Expectation Failed',
          500  => 'Internal Server Error',
          501  => 'Not Implemented',
          502  => 'Bad Gateway',
          503  => 'Service Unavailable',
          504  => 'Gateway Timeout',
          505  => 'HTTP Version Not Supported'
        }
      end

      # 
      # call-seq:
      #   Status.codes -> Array
      #
      # Returns an array of all standard status codes
      def codes
        @codes ||= reason_map.keys
      end

      # 
      # call-seq:
      #   Status.known_code?( code ) -> true or false
      #
      # Is the given code a known standarad code.
      #
      def known_code?( code )
        reason_map.has_key?( code )
      end

      # 
      # call-seq:
      #   Status.response_category( code ) -> Symbol
      #
      # Return one of :informational, :success, :redirection, :client_error,
      # :server_error or :uknown based upon the value of the code.  
      #
      def response_category( code )
        case code
        when 100..199 then :informational
        when 200..299 then :success
        when 300..399 then :redirection 
        when 400..499 then :client_error
        when 500..599 then :server_error
        else :unknown
        end
      end

      #
      # call-seq:
      #   Status.codes_with_no_body -> Set
      #
      # Return the list of all potential status codes that MUST NOT have a
      # message body according to the RFC.
      #
      # Taken from Rack.
      #
      def codes_with_no_body
        @codes_with_no_body ||= Set.new( (100..199).to_a << 204 << 304 )
      end

      #
      # call-seq:
      #   Status.reason_for( code )
      #
      # Return the human readable, default message for a given status code.
      #
      def reason_for( code )
        reason_map[ code ]
      end
    end
  end
end
