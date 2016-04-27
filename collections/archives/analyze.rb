#!/usr/bin/env ruby
#
# Crawls a directory structure and prints a list of issues to stdout.
#
# Will need to be run repeatedly until "Everything OK" is printed (because
# certain issues cannot be detected until others have been fixed).
#

require 'net/http'
require 'nokogiri'
require 'openssl'
require 'tmpdir'

##
# @param schema_name [String] XSD filename
# @return [String] Schema body
#
def get_schema(schema_name)
  uri = 'https://raw.githubusercontent.com/medusa-project/PearTree/develop/' +
  'public/schema/2/' + schema_name
  uri = URI.parse(uri)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  response.code.to_i >= 400 ? nil : response.body
end

def print_usage
  puts 'Usage: ruby analyze.rb <pathname to analyze>'
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


# Download the XML schemas into a temp folder, as Nokogiri has problems
# with schema includes from URLs.
Dir.mktmpdir do |tempdir|
  %w(object.xsd entity.xsd).each do |schema|
    File.open(tempdir + '/' + schema, 'w') do |file|
      file.write(get_schema(schema))
    end
  end

  # validate metadata files
  Dir.glob(pathname + '/**/*.xml').each do |p|
    begin
      doc = Nokogiri::XML(File.read(p), &:noblanks)
      doc.encoding = 'utf-8'

      File.open(tempdir + '/object.xsd') do |content|
        xsd = Nokogiri::XML::Schema(content)
        xsd.validate(doc).each do |error|
          raise error.message
        end
      end
    rescue => e
      puts "Invalid: #{p} (#{e})"
      continue = false
    end
  end
end

exit unless continue

puts 'Everything OK'
