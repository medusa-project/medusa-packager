#!/usr/bin/env ruby
#
# Medusa Map Package Rectifier
#
# Part of the Medusa Packaging Tools:
# https://uofi.app.box.com/notes/43514306333
#
# Crawls a directory structure and attempts to bring it into conformance with
# the Maps Package Profile.
#
# Requires ImageMagick to be installed with the JPEG2000 delegate.
#

require 'fileutils'

# check for the imagemagick jpeg2000 delegate
def im_jp2_delegate_installed?
  delegate_present = false
  `identify -list format`.each_line do |line|
    return true if line.include?('JP2* JP2')
  end
  false
end

def print_usage
  puts 'Usage: ruby map_package_rectifier.rb <pathname to rectify>'
end

unless im_jp2_delegate_installed?
  puts 'This tool requires the ImageMagick JPEG2000 delegate.'
  exit
end

pathname = ARGV[0]
unless pathname
  print_usage
  exit
end

pathname = File.expand_path(pathname)
unless File.exist?(pathname)
  puts "#{pathname} does not exist."
  exit
end

# delete Thumbs.db files
Dir.glob(pathname + '/**/Thumbs.db').each do |p|
  puts "Deleting #{p}"
  File.delete(p)
end

# move access/accessMasters/[bib ID] folders into [bib ID]/access/
Dir.glob(pathname + '/access/accessMasters/*').each do |p|
  dest = pathname + '/' + File.basename(p)
  unless File.directory?(dest)
    puts "Creating #{dest}"
    FileUtils.mkdir_p(dest)
  end
  puts "Moving #{p} to #{dest}/access"
  FileUtils.mv(p, dest + '/access')
end

# move preservation/preservationMasters/[bib ID] folders into
# [bib ID]/preservation/ or, if that already exists, only move the contents
Dir.glob(pathname + '/preservation/preservationMasters/*').each do |p|
  dest = pathname + '/' + File.basename(p)
  unless File.directory?(dest)
    puts "Creating #{dest}"
    FileUtils.mkdir_p(dest)
  end
  puts "Moving #{p} to #{dest}/preservation"
  FileUtils.mv(p, dest + '/preservation')
end

# move [bib ID]/**/*.xml files into [bib ID]/metadata
Dir.glob(pathname + '/**/*.xml').each do |p|
  dest = File.dirname(p) + '/../metadata'
  unless File.directory?(dest)
    puts "Creating #{dest}"
    FileUtils.mkdir_p(dest)
  end
  puts "Moving #{p} to #{dest}"
  FileUtils.mv(p, dest)
end

# delete access folder if present and empty
if File.directory?(pathname + '/access/accessMasters')
  Dir.rmdir(pathname + '/access/accessMasters')
end
if File.directory?(pathname + '/access')
  Dir.rmdir(pathname + '/access')
end

# delete preservation folder if present and empty
if File.directory?(pathname + '/preservation/preservationMasters')
  Dir.rmdir(pathname + '/preservation/preservationMasters')
end
if File.directory?(pathname + '/preservation')
  Dir.rmdir(pathname + '/preservation')
end

# move the contents of "jp2" folders into the parent folder and delete
Dir.glob(pathname + '/*/access/*').
    select{ |p| File.directory?(p) and File.basename(p) == 'jp2' }.each do |p|
  puts "Moving #{p}#{File::SEPARATOR}* up one level"
  Dir.glob(p + '/*').each do |p2|
    begin
      FileUtils.mv(p2, File.dirname(p2) + '/..', force: true)
    rescue => e
      if e.message.start_with?('File exists')
        puts "Unable to move up one level: #{p2}"
      else
        puts e
      end
      exit
    end
  end
  puts "Deleting #{p}"
  FileUtils.rmdir(p)
end

# convert access master .tif files to .jp2
Dir.glob(pathname + '/*/access/*.tif').each do |p|
  jp2_pathname = p.gsub('.tif', '.jp2')
  if File.size(p) > 0
    # [0] selects only the first embedded image, if there are >1
    puts "Converting #{p} to #{jp2_pathname}"
    if system("convert #{p}[0] #{jp2_pathname}")
      puts "Deleting #{p}"
      File.delete(p)
    end
  else
    # If operating on a cloned package, the file size will be 0. In that case,
    # delete the fake .tif and create a fake .jp2.
    puts "Creating fake jp2: #{jp2_pathname}"
    FileUtils.touch(jp2_pathname)
    puts "Deleting fake tif: #{p}"
    File.delete(p)
  end
end
