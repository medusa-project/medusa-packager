#!/usr/bin/env ruby
#
# Traverses an arbitrary file/folder hierarchy and creates LRP AIP XML files
# from its contents.
#
# The output folder structure is the same as the source structure.
#
# Empty folders are ignored.

require 'fileutils'
require 'nokogiri'
require 'time' # adds an "iso8601" method to Time

source_pathname = ARGV[0]
dest_root = ARGV[1]
id_prefix = ARGV[2]
collection_id = ARGV[3]
if !source_pathname or !dest_root or !id_prefix or !collection_id
  puts 'Usage: process.rb <source pathname> <destination root> <ID prefix> '\
      '<collection ID>'
  exit
end

source_pathname = File.expand_path(source_pathname)
unless File.exist?(source_pathname)
  puts "Source pathname does not exist."
  exit
end
unless File.directory?(source_pathname)
  puts 'Source pathname must be a directory.'
  exit
end
dest_root = File.expand_path(dest_root)

def relative_pathname(source_pathname, pathname)
  pathname.reverse.chomp(source_pathname.reverse).reverse
end

def id(source_pathname, pathname, id_prefix)
  id_prefix + '-' + relative_pathname(source_pathname, pathname).
      reverse.chomp('/').reverse.gsub(/[\/\.]/, '-')
end

def id_preserving_slashes(source_pathname, pathname, id_prefix)
  id_prefix + '-' + relative_pathname(source_pathname, pathname).
      reverse.chomp('/').reverse.gsub(/[\.]/, '-')
end

def media_type(pathname)
  'unknown/unknown'
end

def parent_pathname(pathname)
  p = File.directory?(pathname) ? pathname : File.dirname(pathname)
  File.expand_path(p + '/..')
end

Dir.glob(source_pathname + '/**/*').each do |pathname|

  # Exclude empty folders
  next if Dir.glob(pathname + '/*').length < 1

  # Replace . and / with -
  object_id = id(source_pathname, pathname, id_prefix)

  builder = Nokogiri::XML::Builder.new do |xml|
    xml['lrp'].Object("xmlns:lrp" => "http://www.library.illinois.edu/lrp/terms#") {
      xml['lrp'].created {
        xml.text(File.ctime(pathname).utc.iso8601.gsub('+00:00', ''))
      }
      xml['lrp'].lastModified {
        xml.text(File.mtime(pathname).utc.iso8601.gsub('+00:00', ''))
      }
      xml['lrp'].published {
        xml.text('true')
      }
      xml['lrp'].repositoryId {
        xml.text(object_id)
      }
      xml['lrp'].title {
        xml.text(File.basename(pathname))
      }
      xml['lrp'].collectionId {
        xml.text(collection_id)
      }

      parent_dir = File.dirname(pathname)
      if parent_dir.length > source_pathname.length # exclude top-level files/folders
        Dir.glob(parent_dir + '/*').select{ |subpath| subpath == pathname}.
            each_with_index do |subpath, index|
          xml['lrp'].pageNumber {
            xml.text(index + 1)
          }
          break
        end
      end

      parent_path = parent_pathname(pathname)
      if parent_path.length > source_pathname.length
        xml['lrp'].parentId {
          xml.text(id(source_pathname, parent_path, id_prefix))
        }
      end

      xml['lrp'].preservationMasterMediaType {
        xml.text(media_type(pathname))
      }
      xml['lrp'].preservationMasterPathname {
        xml.text(relative_pathname(source_pathname, pathname))
      }
      xml['lrp'].subclass {
        xml.text(File.directory?(pathname) ? 'Directory' : 'File')
      }
    }
  end

  dest = dest_root + '/' +
      id_preserving_slashes(source_pathname, pathname, id_prefix)
  unless File.directory?(dest)
    puts "Creating #{dest}"
    FileUtils.mkdir_p(dest)
  end

  dest_pathname = dest + '/' + File.basename(pathname) + '.xml'
  puts "Writing #{dest_pathname}"
  File.open(dest_pathname, 'w') do |file|
    file.write(builder.to_xml(indent: 2))
  end

  #puts builder.to_xml(indent: 2)
  #puts "\n\n"

end
