
require 'tasks/config'

#--------------------------------------------------------------------------------
# configuration for running rspec.  This shows up as the test:default task
#--------------------------------------------------------------------------------
if spec_config = Configuration.for_if_exist?("test") then
  if spec_config.mode == "spec" then
    namespace :test do

      task :default => :spec

      require 'spec/rake/spectask'
      root_dir = File.expand_path( File.join( File.dirname( __FILE__), ".."))
      lib_dir = File.join( root_dir, "lib" )
      ext_dir = File.join( root_dir, "ext" )
      Spec::Rake::SpecTask.new do |r| 
        r.ruby_opts   = spec_config.ruby_opts
        r.libs        = [ lib_dir, ext_dir, root_dir ]
        r.spec_files  = spec_config.files 
        r.spec_opts   = spec_config.options

        if rcov_config = Configuration.for_if_exist?('rcov') then
          r.rcov      = true
          r.rcov_dir  = rcov_config.output_dir
          r.rcov_opts = rcov_config.rcov_opts
        end
      end

      task :spec => "ext:build"
    end
  end
end
