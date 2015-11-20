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
    FileUtils.mkdir_p("#{base}/access")
    FileUtils.mkdir_p("#{base}/access/accessMasters")
    FileUtils.mkdir_p("#{base}/access/accessMasters/0123456")
    FileUtils.touch("#{base}/access/accessMasters/0123456/0123456_001.jp2")
    FileUtils.touch("#{base}/access/accessMasters/0123456/0123456_key.jp2")
    FileUtils.touch("#{base}/access/accessMasters/0123456/0123456_title.jp2")
    FileUtils.mkdir_p("#{base}/preservation")
    FileUtils.mkdir_p("#{base}/preservation/preservationMasters")
    FileUtils.mkdir_p("#{base}/preservation/preservationMasters/0123456")
    FileUtils.touch("#{base}/preservation/preservationMasters/0123456/0123456_001.tif")
    FileUtils.touch("#{base}/preservation/preservationMasters/0123456/0123456_key.tif")
    FileUtils.touch("#{base}/preservation/preservationMasters/0123456/0123456_title.tif")
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
    assert(output.include?('Everything OK'))
  end

  def test_with_missing_access_folder
    FileUtils.rm_r(fixture_pathname + '/access')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('Missing'))
  end

  def test_with_missing_access_masters_folder
    FileUtils.rm_r(fixture_pathname + '/access/accessMasters')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('Missing'))
  end

  def test_with_invalid_access_bib_id_folder
    FileUtils.mkdir_p(fixture_pathname + '/access/accessMasters/bogus0123456')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('does not begin with'))
  end

  def test_with_invalid_access_file_format_1
    FileUtils.touch(fixture_pathname + '/access/accessMasters/0123456/012345_001.jp2')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_invalid_access_file_format_2
    FileUtils.touch(fixture_pathname + '/access/accessMasters/0123456/0123456_bogus.jp2')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_invalid_access_file_extension
    FileUtils.touch(fixture_pathname + '/access/accessMasters/0123456/0123456_001.bogus')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_missing_preservation_folder
    FileUtils.rm_r(fixture_pathname + '/preservation')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('Missing'))
  end

  def test_with_missing_preservation_masters_folder
    FileUtils.rm_r(fixture_pathname + '/preservation/preservationMasters')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('Missing'))
  end

  def test_with_invalid_preservation_bib_id_folder
    FileUtils.mkdir_p(fixture_pathname + '/preservation/preservationMasters/bogus0123456')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('does not begin with'))
  end

  def test_with_invalid_preservation_file_format_1
    FileUtils.touch(fixture_pathname + '/preservation/preservationMasters/0123456/012345_001.tif')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_invalid_preservation_file_format_2
    FileUtils.touch(fixture_pathname + '/preservation/preservationMasters/0123456/0123456_bogus.tif')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  def test_with_invalid_preservation_file_extension
    FileUtils.touch(fixture_pathname + '/preservation/preservationMasters/0123456/0123456_001.bogus')
    output = run_analyzer(fixture_pathname)
    assert(output.include?('has an incorrect filename format'))
  end

  private

  def run_analyzer(*args)
    `ruby #{__dir__}/../map_package_analyzer.rb #{args.join(' ')}`
  end

end
