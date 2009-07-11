#--
# Copyright (c) 2009 Jeremy Hinegardner
# All rights reserved.  See LICENSE and/or COPYING for details.
#++

module Http
  class RequestParser < Parser

    ## 
    # Callbacks specific to the RequestParser.
    ##

    def on_path( &block )          self.on_path = block         ; end
    def on_query_string( &block )  self.on_query_string = block ; end
    def on_uri( &block )           self.on_uri = block          ; end
    def on_fragment( &block )      self.on_fragment = block     ; end
  end
end

