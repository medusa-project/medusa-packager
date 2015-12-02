#!/usr/bin/env ruby

require 'fileutils'
require_relative 'test_helper'

class MapPackageRectifierTest < Minitest::Test

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
    output = run_rectifier('/bogus/bogus/bogus')
    assert(output.include?('does not exist'))
  end

  def test_with_valid_structure_displays_nothing
    output = run_rectifier(fixture_pathname)
    assert_equal("", output)
  end

  def test_thumbs_files_deleted
    pathname = "#{fixture_pathname}/access/accessMasters/0123456/Thumbs.db"
    FileUtils.touch(pathname)
    run_rectifier(fixture_pathname)
    assert(!File.exists?(pathname))
  end

  def test_jp2_folder_contents_moved_into_parent
    folder_pathname = "#{fixture_pathname}/access/accessMasters/0123456/jp2"
    file_pathname = "#{fixture_pathname}/access/accessMasters/0123456/jp2/bla.jp2"
    FileUtils.mkdir(folder_pathname)
    FileUtils.touch(file_pathname)
    run_rectifier(fixture_pathname)
    assert(File.exists?("#{fixture_pathname}/access/accessMasters/0123456/bla.jp2"))
  end

  def test_jp2_folders_deleted
    folder_pathname = "#{fixture_pathname}/access/accessMasters/0123456/jp2"
    FileUtils.mkdir(folder_pathname)
    run_rectifier(fixture_pathname)
    assert(!File.exists?(folder_pathname))
  end

  def test_tifs_converted_to_jp2s
    tif_pathname = "#{fixture_pathname}/access/accessMasters/0123456/bla.tif"
    jp2_pathname = "#{fixture_pathname}/access/accessMasters/0123456/bla.jp2"
    FileUtils.touch(tif_pathname)
    run_rectifier(fixture_pathname)
    assert(!File.exists?(tif_pathname))
    assert(File.exists?(jp2_pathname))
  end

  private

  def run_rectifier(*args)
    `ruby #{__dir__}/../map_package_rectifier.rb #{args.join(' ')}`
  end

end
