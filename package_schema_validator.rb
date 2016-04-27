#!/usr/bin/env ruby
#
# Crawls a directory structure, validates each XML it finds, and prints
# a list of issues to stdout.
#

require 'net/http'
require 'nokogiri'
require 'openssl'

##
# @param schema_version [Integer]
# @return [String] Schema body
#
def get_schema(schema_version)
  uri = 'https://raw.githubusercontent.com/medusa-project/PearTree/develop/' +
  'public/schema/' + schema_version + '/object.xsd'
  uri = URI.parse(uri)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  response.code.to_i >= 400 ? nil : response.body
end

# The script will check this after each "step" and abort if false.
continue = true

pathname = ARGV[0]
schema_version = ARGV[1]
if !pathname or !schema_version
  puts 'Usage: ruby analyze.rb <pathname to analyze> <schema version>'
  exit
end

pathname = File.expand_path(pathname)
unless File.exist?(pathname)
  puts "#{pathname} does not exist."
  continue = false
end

exit unless continue

xsd = Nokogiri::XML::Schema(get_schema(schema_version))

# validate metadata files
Dir.glob(pathname + '/**/*.xml').each do |p|
  begin
    doc = Nokogiri::XML(File.read(p), &:noblanks)
    doc.encoding = 'utf-8'
    xsd.validate(doc).each do |error|
      raise error.message
    end
  rescue => e
    puts "Invalid: #{p} (#{e})"
    continue = false
  end
end

exit unless continue

puts 'Everything OK'
