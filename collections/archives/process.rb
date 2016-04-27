#!/usr/bin/env ruby
#
# Traverses an arbitrary file/folder hierarchy and creates DLS XML files
# (version 2) from its contents.
#
# The output folder structure is the same as the source structure.
#
# Empty folders are ignored.

require 'digest/md5'
require 'fileutils'
require 'mime/types'
require 'nokogiri'
require 'time' # adds an "iso8601" method to Time

source_pathname = ARGV[0]
dest_root = ARGV[1]
collection_id = ARGV[2]
if !source_pathname or !dest_root or !collection_id
  puts 'Usage: process.rb <source pathname> <destination root> <collection ID>'
  exit
end

source_pathname = File.expand_path(source_pathname)
unless File.exist?(source_pathname)
  puts 'Source pathname does not exist.'
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

def encoded_id(collection_id, unencoded_id)
  # The collection ID adds some "salt," preventing collisions in the case of
  # the same unencoded ID (relative pathname) appearing in multiple
  # collections.
  Digest::MD5.hexdigest(collection_id + unencoded_id)
end

##
# @param root_pathname [String] Root pathname of the collection
# @param pathname[String] Pathname to generate an ID for
# @return [String] Pathname of the given pathname within the root collection
#                  pathname with no leading slash
#
def unencoded_id(root_pathname, pathname)
  relative_pathname(root_pathname, pathname).reverse.chomp('/').reverse
end

Dir.glob(source_pathname + '/**/*').each do |pathname|
  # Skip junk files
  next if %w(Thumbs.db .DS_Store).include?(File.basename(pathname))

  # Skip empty folders
  next if File.directory?(pathname) and Dir.glob(pathname + '/*').length < 1

  object_id = encoded_id(collection_id, unencoded_id(source_pathname, pathname))

  builder = Nokogiri::XML::Builder.new do |xml|
    xml['dls'].Object("xmlns:dls" => "http://digital.library.illinois.edu/terms#") {
      # repositoryId
      xml['dls'].repositoryId {
        xml.text(object_id)
      }

      # collectionId
      xml['dls'].collectionId {
        xml.text(collection_id)
      }

      # parentId
      parent_path = File.expand_path(pathname + '/..')
      if parent_path.length > source_pathname.length
        xml['dls'].parentId {
          xml.text(encoded_id(collection_id,
              unencoded_id(source_pathname, parent_path)))
        }
      end

      # published
      xml['dls'].published {
        xml.text('true')
      }

      # pageNumber
      parent_dir = File.dirname(pathname)
      if parent_dir.length > source_pathname.length # exclude top-level files/folders
        Dir.glob(parent_dir + '/*').select{ |subpath| subpath == pathname}.
            each_with_index do |subpath, index|
          xml['dls'].pageNumber {
            xml.text(index + 1)
          }
          break
        end
      end

      # created
      xml['dls'].created {
        xml.text(File.ctime(pathname).utc.iso8601.gsub('+00:00', ''))
      }

      # lastModified
      xml['dls'].lastModified {
        xml.text(File.mtime(pathname).utc.iso8601.gsub('+00:00', ''))
      }

      # variant
      xml['dls'].variant {
        xml.text(File.directory?(pathname) ? 'Directory' : 'File')
      }

      # preservationMaster*
      if File.file?(pathname)
        xml['dls'].preservationMasterPathname {
          xml.text(relative_pathname(source_pathname, pathname))
        }
        xml['dls'].preservationMasterMediaType {
          xml.text(MIME::Types.of(pathname).first.to_s)
        }
      end

      # title
      xml['dls'].title {
        xml.text(File.basename(pathname))
      }
    }
  end

  dest = dest_root + '/' + unencoded_id(source_pathname, pathname)
  unless File.directory?(dest)
    puts "Creating #{dest}"
    FileUtils.mkdir_p(dest)
  end

  dest_pathname = dest + '/item_' + File.basename(pathname) + '.xml'
  puts "Writing #{dest_pathname}"
  File.open(dest_pathname, 'w') do |file|
    file.write(builder.to_xml(indent: 2))
  end

  #puts builder.to_xml(indent: 2) + "\n\n"

end
