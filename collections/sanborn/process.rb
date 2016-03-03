#!/usr/bin/env ruby

require 'CSV'
require 'fileutils'
require 'nokogiri'
require 'time' # adds an "iso8601" method to Time

def decimal_degrees(dms)
  #  {decimal degrees} = {degrees} + {minutes}/60 + {seconds}/3600
  dms.scan(/([NESW])\s([0-8]?[0-9]|90)°([0-5]?[0-9]ʹ)?([0-5]?[0-9](.[0-9]+)?ʺ)/).map{|d,x,y,z|d.gsub(/[SW]/,'-').gsub(/[NE]/,'')+(x.to_f+y.to_f/60+z.to_f/3600).to_s}[0]
end

source_pathname = ARGV[0]
dest_root = ARGV[1]
if !source_pathname or !dest_root
  puts 'Usage: process.rb <source TSV file> <destination root pathname>'
  exit
end

if !source_pathname.end_with?('.tsv')
  puts 'Source pathname must be a .tsv file.'
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

# quote_char needs to be a character that the source data is guaranteed not
# to contain: in this case, a unicode rocket ship.
tsv = CSV.parse(File.read(source_pathname), headers: true, col_sep: "\t", quote_char: '🚀')
tsv.each_with_index do |row, i|
  # Uncomment to run individual rows (start with 0; header doesn't count)
  #next unless (i == 14 or i == 13)
  r = row.to_hash

  object_id = r['Repository ID']

  next if object_id.nil?

  puts "Row #{i}: #{object_id}"

  builder = Nokogiri::XML::Builder.new do |xml|
    xml['lrp'].Object("xmlns:lrp" => "http://www.library.illinois.edu/lrp/terms#") {
      xml['lrp'].bibId {
        xml.text(r['Local Bib ID'])
      }
      xml['lrp'].created {
        if r['Date created'].nil?
          xml.text(Time.now.utc.iso8601)
        else
          parts = r['Date created'].split('/')
          xml.text(Time.parse("#{parts[2]}/#{parts[0]}/#{parts[1]}").utc.iso8601.gsub('+00:00', ''))
        end
      }

      xml['lrp'].lastModified {
        if r['Date modified'].nil?
          xml.text(Time.now.utc.iso8601)
        else
          parts = r['Date modified'].split('/')
          xml.text(Time.parse("#{parts[2]}/#{parts[0]}/#{parts[1]}").utc.iso8601.gsub('+00:00', ''))
        end
      }

      xml['lrp'].published {
        xml.text('true')
      }
      xml['lrp'].repositoryId {
        xml.text(object_id)
      }
      if r['File Name'].nil?
        children = tsv.find_all{ |child| child['Local Bib ID'] == r['Local Bib ID'] && child['File Name'] }
        if children.any?
          xml['lrp'].representativeItemId {
            xml.text(children.first.to_hash['File Name'])
          }
        end
      else
        xml['lrp'].representativeItemId {
          xml.text(object_id)
        }
      end

      xml['lrp'].alternativeTitle {
        xml.text(r['Alternative Title'])
      }
      if r['Scale']
        r['Scale'].split(';').each do |scale|
          xml['lrp'].cartographicScale {
            xml.text(scale.strip)
          }
        end
      end
      xml['lrp'].creator {
        xml.text(r['Creator'])
      }
      xml['lrp'].dateCreated {
        xml.text(r['Date of Publication'])
      }
      xml['lrp'].dimensions {
        xml.text(r['Dimensions'])
      }
      if r['Extent']
        r['Extent'].split(';').each do |extent|
          xml['lrp'].extent {
            xml.text(extent.strip)
          }
        end
      end
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
      if r['Notes']
        r['Notes'].gsub('. ;', '.;').split('.;').each do |note|
          xml['lrp'].notes {
            xml.text(note.strip)
          }
        end
      end
      xml['lrp'].physicalLocation {
        xml.text(r['Physical Location'])
      }
      xml['lrp'].publicationPlace {
        xml.text(r['Place of Publication'])
      }
      xml['lrp'].publisher {
        xml.text(r['Publisher'])
      }
      if r['Coverage-Spatial']
        r['Coverage-Spatial'].split(';').each do |c|
          xml['lrp'].spatialCoverage {
            xml.text(c.strip)
          }
        end
      end
      if r['Genre']
        r['Genre'].split(';').each do |genre|
          xml['lrp'].subject {
            xml.text(genre.strip)
          }
        end
      end
      if r['Subject']
        r['Subject'].split(';').each do |subject|
          xml['lrp'].subject {
            xml.text(subject.strip)
          }
        end
      end

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
        #xml.text(r['Collection ID'])
        xml.text('sanborn') # TODO: fix
      }
      unless r['Page Number'].nil?
        xml['lrp'].pageNumber {
          xml.text(r['Page Number'])
        }
      end
      unless r['Parent ID'].nil?
        xml['lrp'].parentId {
          xml.text(r['Parent ID'])
        }
      end
      unless r['File Name'].nil?
        xml['lrp'].preservationMasterMediaType {
          xml.text('image/tiff')
        }
        xml['lrp'].preservationMasterPathname {
          xml.text("/#{r['Local Bib ID']}/preservation/#{r['File Name']}".chomp('.jp2') + '.tif')
        }
      end

      subclass = r['Object Class']
      unless subclass.nil?
        if subclass.downcase == 'frontmatter'
          xml['lrp'].subclass {
            xml.text('FrontMatter')
          }
        elsif %w(index key page title).include?(subclass.downcase)
          xml['lrp'].subclass {
            xml.text(subclass.capitalize)
          }
        end
      end

      unless r['Subpage Number'].nil?
        xml['lrp'].subpageNumber {
          xml.text(r['Subpage Number'])
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
