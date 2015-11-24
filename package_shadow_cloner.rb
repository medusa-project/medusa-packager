#!/usr/bin/env ruby
#
# Medusa Shadow Cloner
#
# Part of the Medusa Packaging Tools:
# https://uofi.app.box.com/notes/43514306333
#
# Creates a duplicate of a package, using empty files in place of the
# originals. This makes it easy to clone even very large packages locally for
# testing purposes, without worrying about modifying the source package.
#

require 'fileutils'

def print_usage
  puts 'Usage: ruby package_shadow_cloner.rb <pathname to clone> <destination pathname>'
end

source_pathname = ARGV[0]
unless source_pathname
  print_usage
  exit
end

dest_pathname = ARGV[1]
unless dest_pathname
  print_usage
  exit
end

source_pathname = File.expand_path(source_pathname)
unless File.exist?(source_pathname)
  puts "#{source_pathname} does not exist."
  exit
end

dest_pathname = File.expand_path(dest_pathname)
if File.exist?(dest_pathname) and File.file?(dest_pathname)
  puts "#{dest_pathname} exists and is not a directory."
  exit
elsif !File.exist?(dest_pathname)
  FileUtils.mkdir_p(dest_pathname)
end

Dir.glob(source_pathname + '/**/*').each do |src_path|
  dest_path = src_path.gsub(source_pathname, dest_pathname)
  if File.directory?(src_path)
    FileUtils.mkdir(dest_path)
  else
    FileUtils.touch(dest_path)
  end
end
