#--
# Copyright (c) 2009 Jeremy Hinegardner
# All rights reserved.  See LICENSE and/or COPYING for details.
#++

require 'http/request_parser_callbacks'
module Http
  class RequestParser < Parser
    include RequestParserCallbacks
  end
end

