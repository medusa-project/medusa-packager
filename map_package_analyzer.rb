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

def print_usage
  puts 'Usage: ruby map_package_analyzer.rb <pathname to analyze>'
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
  unless File.basename(p).match(/^[0-9]{7}/)
    puts "#{p} does not begin with a valid bib ID."
    continue = false
  end
end

exit unless continue

# check that each bib ID folder contains access, preservation, and metadata
# folders
Dir.glob(pathname + '/*').select{ |p| File.directory?(p) }.each do |p|
  any_missing = false
  %w(access preservation metadata).each do |expected|
    unless File.directory?(p + '/' + expected)
      any_missing = true
      puts "Missing folder: #{p}"
    end
  end
  continue = false if any_missing
end

exit unless continue

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

exit unless continue

bib_ids_with_access_files = Set.new
Dir.glob(pathname + '/*/access/*').select{ |p| File.file?(p) }.each do |p|
  bib_ids_with_access_files << File.basename(File.dirname(File.dirname(p)))
end

bib_ids_with_preservation_files = Set.new
Dir.glob(pathname + '/*/preservation/*').select{ |p| File.file?(p) }.each do |p|
  bib_ids_with_preservation_files << File.basename(File.dirname(File.dirname(p)))
end

tmp1 = bib_ids_with_access_files - bib_ids_with_preservation_files
if tmp1.any?
  puts 'Contains preservation masters but no access masters:' + tmp1.join("\n")
  continue = false
end

tmp2 = bib_ids_with_preservation_files - bib_ids_with_access_files
if tmp2.any?
  puts 'Contains access masters but no preservation masters:' + tmp2.join("\n")
  continue = false
end

exit unless continue

puts 'Everything OK'
