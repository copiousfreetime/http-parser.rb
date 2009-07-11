module HttpParser
  module Paths
    # The root directory of the project is considered to be the parent directory
    # of the 'lib' directory.
    #   
    def root_dir
      @root_dir ||= (
        path_parts = ::File.expand_path(__FILE__).split(::File::SEPARATOR)
        lib_index  = path_parts.rindex("lib")
        path_parts[0...lib_index].join(::File::SEPARATOR) + ::File::SEPARATOR
      )
    end 

    def root_path( sub, *args )
      sub_path( root_dir, sub, *args )
    end

    def lib_path( *args )
      root_path( "lib", *args )
    end 

    def spec_path( *args )
      root_path( "spec", *args )
    end

    def tmp_path( *args )
      home_path( "tmp", *args )
    end

    def sub_path( parent, sub, *args )
      sp = ::File.join( parent, sub ) + File::SEPARATOR
      sp = ::File.join( sp, *args ) if args
    end

    extend self
  end
  extend Paths
end
