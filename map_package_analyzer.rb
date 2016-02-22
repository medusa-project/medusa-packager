#!/usr/bin/env ruby
#
# Medusa Map Package Analyzer
#
# Part of the Medusa Packaging Tools:
# https://uofi.app.box.com/notes/43514306333
#
# Crawls a directory structure and prints a list of issues to stdout.
#
# Will need to be run repeatedly until "Everything OK" is printed (because
# certain issues cannot be detected until others have been fixed).
#

require 'net/http'
require 'openssl'

##
# @param schema_name [String] XSD filename
# @return [String] Schema body
#
def get_schema(schema_name)
  uri = 'https://raw.githubusercontent.com/medusa-project/PearTree/develop/' +
  'public/schema/1/' + schema_name
  uri = URI.parse(uri)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  response.code.to_i >= 400 ? nil : response.body
end

def print_usage
  puts 'Usage: ruby map_package_analyzer.rb <pathname to analyze>'
end

##
# @param doc [Nokogiri::XML::Document]
# @param schema [String] Schema body
# @raise [RuntimeError] If validation fails
# @return [void]
#
def validate(doc, schema)
  xsd = Nokogiri::XML::Schema(schema)
  xsd.validate(doc).each do |error|
    raise error.message
  end
end

# The script will check this after each "step" and abort if false.
continue = true

pathname = ARGV[0]
unless pathname
  print_usage
  exit
end

pathname = File.expand_path(pathname)
unless File.exist?(pathname)
  puts "#{pathname} does not exist."
  continue = false
end

exit unless continue

# check that all folders within the root package folder are bib ID folders
Dir.glob(pathname + '/*').select{ |p| File.directory?(p) }.each do |p|
  filename = File.basename(p)
  # also allow a folder called "source"
  unless filename.match(/^[0-9]{7}/) or filename == 'source'
    puts "#{p} does not begin with a valid bib ID."
    continue = false
  end
end

exit unless continue

# check that each bib ID folder contains access, preservation, and metadata
# folders
Dir.glob(pathname + '/*').select{ |p| File.directory?(p) }.each do |p|
  expected_folders = %w(access metadata preservation)
  any_missing = false
  expected_folders.each do |expected|
    unless File.directory?(p + '/' + expected)
      any_missing = true
      puts "Missing folder: #{p}/#{expected}"
    end
  end
  continue = false if any_missing

  actual_folders = Dir.glob(p + '/*').select{ |p| File.directory?(p) }.
      map{ |p| File.basename(p) }
  extra_folders = actual_folders - expected_folders
  extra_folders.each do |p2|
    continue = false
    puts "Extraneous folder: #{p}#{File::SEPARATOR}#{p2}"
  end
end

# check for properly-named files within each access folder
Dir.glob(pathname + '/*/access/*').select{ |p| File.file?(p) }.each do |p|
  ok = false
  parts = File.basename(p).split('_')
  if parts.length == 2
    suffix = parts[1].split('.').first
    if parts[0].match(/^[0-9]{7}/) and
        (suffix.match(/^[0-9]{3}\b/) or %w(key title).include?(suffix))
      if File.extname(p) == '.jp2'
        ok = true
      end
    end
  end
  unless ok
    puts "#{p} has an incorrect filename format."
    continue = false
  end
end

# check for properly-named files within each preservation folder
Dir.glob(pathname + '/*/preservation/*').select{ |p| File.file?(p) }.each do |p|
  ok = false
  parts = File.basename(p).split('_')
  if parts.length == 2
    suffix = parts[1].split('.').first
    if parts[0].match(/^[0-9]{7}/) and
        (suffix.match(/^[0-9]{3}\b/) or %w(key title).include?(suffix))
      if File.extname(p) == '.tif'
        ok = true
      end
    end
  end
  unless ok
    puts "#{p} has an incorrect filename format."
    continue = false
  end
end

Dir.glob(pathname + '/*').select{ |p| File.directory?(p) }.each do |p|
  unless Dir.glob(p + '/access/*').any?
    puts 'No access master(s): ' + File.basename(p)
    continue = false
  end
  unless Dir.glob(p + '/preservation/*').any?
    puts 'No preservation master(s): ' + File.basename(p)
    continue = false
  end
  unless Dir.glob(p + '/metadata/item_*.xml').any?
    puts 'No metadata: ' + File.basename(p)
    continue = false
  end
end

# validate item metadata files
item_schema = get_schema('object.xsd')
Dir.glob(pathname + '/metadata/item_*.xml').each do |p|
  begin
    doc = Nokogiri::XML(File.read(p), &:noblanks)
    doc.encoding = 'utf-8'
    validate(doc, schema)
  rescue => e
    puts "Invalid: #{p} (#{e})"
    continue = false
  end
end

exit unless continue

puts 'Everything OK'
