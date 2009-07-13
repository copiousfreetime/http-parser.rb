module Http
  #
  # A case insensitive Hash-like object that allows keys to have multiple values.
  #
  # The original case of the header name is store as the keys.  If a header
  # field shows up more than once with different cases, the first casing is the
  # one that is used.
  #
  # In the case where multiple values are seen, the +value+ is the join(",") of
  # all the values.
  #
  # All keys are strings, and all values are Strings or Array's of strings.
  #
  class Headers
    class << Headers
      # From Thin
      def header_format
        @header_format ||= "%s: %s\r\n".freeze
      end

      #
      # call-seq:
      #   Headers[ "a", 1, "b", 2 ] -> Headers
      #
      # Create from an array, in the same manner as +Hash[]+ but follows the
      # semantics of Headers in that a key can appear more than once
      #
      def []( *args )
        raise ArgumentError, "odd number of arguments for Headers" unless (args.size % 2 == 0)
        h = Headers.new
        (0...args.size).step( 2 ) do |idx|
          key = args[idx].to_s
          val = args[idx+1].to_s
          h[key] = val
        end
        return h 
      end
    end

    #
    # Returns a new Headers instance possibly initialized from the given Hash.
    #
    def initialize( hash = {} )
      @keys = {}
      @values = {}
      hash.each_pair do |k,v| 
        ks = k.to_s
        down_key = ks.downcase
        @keys[down_key] = ks
        @values[down_key] = case v
                            when String then v
                            when Array then v
                            when nil then v
                            else v.to_s
                            end
      end
    end

    #
    # call-seq: 
    #   headers.to_hash
    #
    # Return all the headers as an acutal Hash.
    #
    # Keys will be the case-sensitive version, and the values will be the
    # command separated list of values for the key.
    #
    def to_hash
      h = {}
      @keys.each_pair do |dk,key|
        value = @values[dk]
        h[key] = value
      end
      return h
    end

    #
    # call-seq:
    #   headers[key] -> value
    #   headers.fetch( key ) -> value
    #
    # return the value for the given key.  This is the 'pre joined' state, that
    # is, if there is more than one value for the key, an Array of all the
    # values will be returned.
    #
    def fetch( k )
      @values[ k.to_s.downcase ]
    end
    alias [] fetch
    
    #
    # call-seq:
    #   headers[key] = value -> value
    #   headers.store( key, value ) -> value
    #
    # Store the give string value in the hash.  The uniqueness of a key is by the
    # downcase of they key, but the actual 'key' is the cased version of the
    # last key encountered.  That is:
    #
    #   headers['Set-cookie2'] = cookie2
    #   headers['Set-Cookie2'] = cookie1
    #
    # Accessing headers['set-cookie2'] will return cookie1,cookie2
    # looking at headers.keys() you will see 'Set-Cookie2' not 'Set-cookie2',
    #
    # If the value is not a string, #to_s is invoked on the value before
    # storing.
    #
    def store( k, v )
      dk = k.to_s.downcase
      v = v.to_s
      old_val = @values.delete( dk )
      new_val = case old_val
        when nil then v
        when Array then old_val << v
        else [ old_val, v ]
      end
      @keys[dk] = k
      @values[dk] = new_val
    end
    alias []= store

    #
    # call-seq:
    #   headers.delete( key ) -> value
    #
    # delete the given key, returning its value
    #
    def delete( k )
      dk = k.to_s.downcase
      @keys.delete( dk )
      @values.delete( dk )
    end

    #
    # call-seq:
    #   headers.keys -> Array
    # 
    # Return the cased versions of all the keys
    #
    def keys
      @keys.values
    end

    #
    # call-seq:
    #   headers.values -> Array
    # 
    # Return values, this is their 'pre' joined state.
    #
    def values
      @values.values
    end

    #
    # call-seq:
    #   headers.size -> Integer
    # 
    # The number of headers
    #
    def size
      @values.size
    end

    #
    # call-seq:
    #   headers.empty? -> bool
    #
    # Is the Headers empty or not
    #
    def empty?
      @values.empty?
    end

    #
    # call-seq:
    #   headers.clear -> nil
    #
    # remove all key/value pairs
    #
    def clear
      @keys.clear
      @values.clear
      nil
    end
  end
end
