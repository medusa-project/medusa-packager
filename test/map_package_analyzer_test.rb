#!/usr/bin/env ruby

require 'fileutils'
require_relative 'test_helper'

class MapPackageAnalyzerTest < Minitest::Test

  FIXTURE_FOLDER = 'tmp'

  def fixture_pathname
    "#{__dir__}/#{FIXTURE_FOLDER}"
  end

  def setup
    # create a valid package folder structure
    base = fixture_pathname
    FileUtils.mkdir_p("#{base}/0123456/access")
    FileUtils.mkdir_p("#{base}/0123456/metadata")
    FileUtils.mkdir_p("#{base}/0123456/preservation")

    FileUtils.touch("#{base}/0123456/access/0123456_001.jp2")
    FileUtils.touch("#{base}/0123456/access/0123456_key.jp2")
    FileUtils.touch("#{base}/0123456/access/0123456_title.jp2")
    FileUtils.touch("#{base}/0123456/metadata/item_0123456.xml")
    FileUtils.touch("#{base}/0123456/preservation/0123456_001.tif")
    FileUtils.touch("#{base}/0123456/preservation/0123456_key.tif")
    FileUtils.touch("#{base}/0123456/preservation/0123456_title.tif")
  end

  def teardown
    FileUtils.rm_r(fixture_pathname)
  end

  def test_no_arguments_displays_usage
    output = `ruby #{__dir__}/../map_package_analyzer.rb`
    assert(output.start_with?('Usage:'))
  end

  def test_invalid_path_displays_error
    output = run_analyzer('/bogus/bogus/bogus')
    assert(output.include?('does not exist'))
  end

  def test_with_valid_structure_displays_ok
    output = run_analyzer(fixture_pathname)
    puts output
    assert(output.include?('Everything OK'))
  end

  def test_with_invalid_bib_id_folder
    FileUtils.mkdir_p(fixture_pathname + '/bogus0123456')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('does not begin with'))
  end

  def test_bib_id_folder_with_extraneous_subfolder
    FileUtils.mkdir_p(fixture_pathname + '/0123456/bogus')
    output = run_analyzer(fixture_pathname)
    assert(output.start_with?('Extraneous folder:'))
  end

  def test_with_missing_access_folder
    FileUtils.rm_r(fixture_pathname + '/0123456/access')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('Missing'))
  end

  def test_with_invalid_access_file_format_1
    FileUtils.touch(fixture_pathname + '/0123456/access/012345_001.jp2')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_invalid_access_file_format_2
    FileUtils.touch(fixture_pathname + '/0123456/access/0123456_bogus.jp2')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_invalid_access_file_extension
    FileUtils.touch(fixture_pathname + '/0123456/access/0123456_001.bogus')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_missing_preservation_folder
    FileUtils.rm_r(fixture_pathname + '/0123456/preservation')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('Missing'))
  end

  def test_with_invalid_preservation_file_format_1
    FileUtils.touch(fixture_pathname + '/0123456/preservation/012345_001.tif')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_invalid_preservation_file_format_2
    FileUtils.touch(fixture_pathname + '/0123456/preservation/0123456_bogus.tif')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_invalid_preservation_file_extension
    FileUtils.touch(fixture_pathname + '/0123456/preservation/0123456_001.bogus')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_missing_access_masters
    base = fixture_pathname
    Dir.glob("#{base}/0123456/access/*").each do |p|
      FileUtils.rm_r(p)
    end
    output = run_analyzer(base)
    assert(output.include?('No access master(s): 0123456'))
  end

  def test_with_missing_preservation_masters
    base = fixture_pathname
    Dir.glob("#{base}/0123456/preservation/*").each do |p|
      FileUtils.rm_r(p)
    end
    output = run_analyzer(base)
    assert(output.include?('No preservation master(s): 0123456'))
  end

  private

  def run_analyzer(*args)
    `ruby #{__dir__}/../map_package_analyzer.rb #{args.join(' ')}`
  end

end
