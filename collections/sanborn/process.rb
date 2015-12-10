#!/usr/bin/env ruby

require 'CSV'
require 'fileutils'
require 'nokogiri'

def decimal_degrees(dms)
  #  {decimal degrees} = {degrees} + {minutes}/60 + {seconds}/3600
  dms.scan(/([NESW])\s([0-8]?[0-9]|90)°([0-5]?[0-9]ʹ)?([0-5]?[0-9](.[0-9]+)?ʺ)/).map{|d,x,y,z|d.gsub(/[SW]/,'-').gsub(/[NE]/,'')+(x.to_f+y.to_f/60+z.to_f/3600).to_s}[0]
end

source_pathname = ARGV[0]
dest_root = ARGV[1]
if !source_pathname or !dest_root
  puts 'Usage: process.rb <source CSV file> <destination root pathname>'
  exit
end

if !source_pathname.end_with?('.csv')
  puts 'Source pathname must be a .csv file.'
  exit
end

source_pathname = File.expand_path(source_pathname)
unless File.exist?(source_pathname)
  puts "#{source_pathname} does not exist."
  exit
end
dest_root = File.expand_path(dest_root)
unless File.exist?(dest_root)
  puts "#{dest_root} does not exist."
  exit
end

page_number = 0
csv = CSV.parse(File.read(source_pathname), headers: true)
csv.each_with_index do |row, i|
  # Uncomment to run individual rows (start with 0; header doesn't count)
  #next unless (i == 14 or i == 13)
  r = row.to_hash

  object_id = r['File Name'] || r['Local Bib ID']

  puts "Row #{i}: #{object_id}"

  builder = Nokogiri::XML::Builder.new do |xml|
    xml['lrp'].Object("xmlns:lrp" => "http://www.library.illinois.edu/lrp/terms#") {
      xml['lrp'].created {
        parts = r['Date created'].split('/')
        xml.text(DateTime.parse("20#{parts[2]}/#{parts[0]}/#{parts[1]}").iso8601.gsub('+00:00', '') + 'Z')
      }
      xml['lrp'].lastModified {
        parts = r['Date modified'].split('/')
        xml.text(DateTime.parse("20#{parts[2]}/#{parts[0]}/#{parts[1]}").iso8601.gsub('+00:00', '') + 'Z')
      }
      xml['lrp'].published {
        xml.text('true')
      }
      xml['lrp'].repositoryId {
        xml.text(object_id)
      }

      xml['lrp'].alternativeTitle {
        xml.text(r['Alternative Title'])
      }
      xml['lrp'].cartographicScale {
        xml.text(r['Scale'])
      }
      xml['lrp'].creator {
        xml.text(r['Creator'])
      }
      xml['lrp'].dateCreated {
        xml.text(r['Date of Publication'])
      }
      xml['lrp'].dimensions {
        xml.text(r['Dimensions'])
      }
      xml['lrp'].extent {
        xml.text(r['Extent'])
      }
      xml['lrp'].isPartOf {
        xml.text(r['Collection'])
      }
      if r['Coordinates']
        long, lat = r['Coordinates'].split('/')
        dd = decimal_degrees(lat)
        xml['lrp'].latitude {
          xml.text(dd)
        } if dd
        dd = decimal_degrees(long)
        xml['lrp'].longitude {
          xml.text(dd)
        } if dd
      end
      xml['lrp'].notes {
        xml.text(r['Notes'])
      }
      xml['lrp'].physicalLocation {
        xml.text(r['Physical Location'])
      }
      xml['lrp'].publicationPlace {
        xml.text(r['Place of Publication'])
      }
      xml['lrp'].publisher {
        xml.text(r['Publisher'])
      }
      xml['lrp'].spatialCoverage {
        xml.text(r['Coverage-Spatial'])
      }
      r['Genre'].split('; ').each do |genre|
        xml['lrp'].subject {
          xml.text(genre)
        }
      end
      r['Subject'].split('; ').each do |subject|
        xml['lrp'].subject {
          xml.text(subject)
        }
      end if r['Subject']
      xml['lrp'].title {
        xml.text(r['Title'])
      }
      xml['lrp'].type {
        xml.text(r['Type'])
      }

      unless r['File Name'].nil?
        xml['lrp'].accessMasterMediaType {
          xml.text('image/jp2')
        }
        xml['lrp'].accessMasterPathname {
          xml.text("/#{r['Local Bib ID']}/access/#{r['File Name']}".chomp('.jp2') + '.jp2')
        }
      end
      xml['lrp'].collectionId {
        xml.text('sanborn')
      }
      if r['File Name'].nil?
        page_number = 0
      else
        parents = csv.find_all{|parent| parent['Local Bib ID'] == r['Local Bib ID'] && parent['File Name'].nil?}
        if parents.any?
          page_number += 1
          xml['lrp'].pageNumber {
            xml.text(page_number)
          }
          xml['lrp'].parentId {
            xml.text(parents.first.to_hash['Local Bib ID'])
          }
        end
      end
      unless r['File Name'].nil?
        xml['lrp'].preservationMasterMediaType {
          xml.text('image/tiff')
        }
        xml['lrp'].preservationMasterPathname {
          xml.text("/#{r['Local Bib ID']}/preservation/#{r['File Name']}".chomp('.tif') + '.tif')
        }
      end
    }
  end

  dest = dest_root + '/' + r['Local Bib ID'] + '/metadata'
  unless File.directory?(dest)
    puts "Creating #{dest}"
    FileUtils.mkdir_p(dest)
  end
  filename = (r['File Name'].nil?) ? r['Local Bib ID'] : r['File Name']
  filename = filename.gsub('.jp2', '')
  dest_pathname = "#{dest}/item_#{filename}.xml"
  puts "Writing #{dest_pathname}"
  File.open(dest_pathname, 'w') do |file|
    file.write(builder.to_xml(indent: 2))
  end

end
