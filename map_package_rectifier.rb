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

# move the contents of "jp2" folders into the parent folder and delete
Dir.glob(pathname + '/access/accessMasters/*').each do |p|
  jp2_folder = p + File::SEPARATOR + 'jp2'
  if File.exist?(jp2_folder)
    puts "Moving #{jp2_folder}#{File::SEPARATOR}* up one level"
    Dir.glob(jp2_folder + '/*').each do |p|
      begin
        FileUtils.mv(p, File.dirname(p) + '/..', force: true)
      rescue => e
        if e.message.start_with?('File exists')
          puts "Unable to move up one level: #{p}"
        else
          puts e
        end
        exit
      end
    end
    puts "Deleting #{jp2_folder}"
    FileUtils.rmdir(jp2_folder)
  end
end

# convert access master .tif files to .jp2
Dir.glob(pathname + '/access/**/*.tif').each do |p|
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
