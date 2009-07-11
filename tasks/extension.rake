require 'tasks/config'
require 'pathname'

#-----------------------------------------------------------------------
# Extensions
#-----------------------------------------------------------------------
if ext_config = Configuration.for_if_exist?('extension') then

  namespace :ext do  
    desc "Build the extension(s)"
    task :build => :clean do
      ext_config.configs.each do |extension|
        path = Pathname.new(extension)
        parts = path.split
        conf = parts.last
        Dir.chdir(path.dirname) do |d| 
          ruby conf.to_s
          sh "make"
        end 
      end 
    end 

    task :clean do
      ext_config.configs.each do |extension|
        path = Pathname.new(extension)
        parts = path.split
        conf = parts.last
        Dir.chdir( path.dirname )do |d| 
          if File.exist?("Makefile") then
            sh "make clean"
          end
          rm_f "rbconfig.rb"
        end 
      end 
    end 

    task :clobber do
      ext_config.configs.each do |extension|
        path = Pathname.new(extension)
        parts = path.split
        conf = parts.last
        Dir.chdir( path.dirname )do |d| 
          if File.exist?("Makefile") then
            sh "make distclean"
          end
          rm_f "rbconfig.rb"
        end 
      end 
    end 
  end
end

