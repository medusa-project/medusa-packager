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

# check for a top-level "access" folder
access_path = sprintf('%s%s%s', pathname, File::SEPARATOR, 'access')
unless File.exist?(access_path)
  puts "Missing #{access_path}"
  exit
end

# check for an "access/accessMasters" folder
access_masters_path = sprintf('%s%s%s', access_path, File::SEPARATOR,
    'accessMasters')
unless File.exist?(access_masters_path)
  puts "Missing #{access_masters_path}"
  exit
end

# check for bib ID folders within the accessMasters folder
access_bib_ids = []
Dir.glob(sprintf("%s%s*", access_masters_path, File::SEPARATOR)).
    select{ |p| File.directory?(p) }.each do |p|
  unless File.basename(p).match(/^[0-9]{7}/)
    puts "#{p} does not begin with a valid bib ID."
    exit
  end
  access_bib_ids << File.basename(p)
end

# check for properly-named files within the bib ID folder
Dir.glob(sprintf("%s%s*%s*", access_masters_path, File::SEPARATOR, File::SEPARATOR)).
    select{ |p| File.file?(p) }.each do |p|
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
    exit
  end
end

# check for a top-level "preservation" folder
preservation_path = sprintf('%s%s%s', pathname, File::SEPARATOR, 'preservation')
unless File.exist?(preservation_path)
  puts "Missing #{preservation_path}"
  exit
end

# check for a "preservation/preservationMasters" folder
preservation_masters_path = sprintf('%s%s%s', preservation_path,
    File::SEPARATOR, 'preservationMasters')
unless File.exist?(preservation_masters_path)
  puts "Missing #{preservation_masters_path}"
  exit
end

# check for bib ID folders within the preservationMasters folder
preservation_bib_ids = []
Dir.glob(sprintf("%s%s*", preservation_masters_path, File::SEPARATOR)).
    select{ |p| File.directory?(p) }.each do |p|
  unless File.basename(p).match(/^[0-9]{7}/)
    puts "#{p} does not begin with a valid bib ID."
    exit
  end
  preservation_bib_ids << File.basename(p)
end

# check for properly-named files within the bib ID folder
Dir.glob(sprintf("%s%s*%s*", preservation_masters_path, File::SEPARATOR, File::SEPARATOR)).
    select{ |p| File.file?(p) }.each do |p|
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
    exit
  end
end

tmp = access_bib_ids - preservation_bib_ids
if tmp.any?
  puts 'Access masters not present in preservation masters:'
  puts tmp.join("\n")
  exit
end

tmp = preservation_bib_ids - access_bib_ids
if tmp.any?
  puts 'Preservation masters not present in access masters:'
  puts tmp.join("\n")
  exit
end

puts 'Everything OK'
