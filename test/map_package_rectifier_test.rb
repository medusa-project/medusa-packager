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
    FileUtils.mkdir_p("#{base}/0123456/access")
    FileUtils.touch("#{base}/0123456/access/0123456_001.jp2")
    FileUtils.touch("#{base}/0123456/access/0123456_key.jp2")
    FileUtils.touch("#{base}/0123456/access/0123456_title.jp2")
    FileUtils.mkdir_p("#{base}/0123456/preservation")
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
    output = run_rectifier('/bogus/bogus/bogus')
    assert(output.include?('does not exist'))
  end

  def test_with_valid_structure_displays_nothing
    output = run_rectifier(fixture_pathname)
    assert_equal('', output)
  end

  def test_thumbs_files_deleted
    pathname = "#{fixture_pathname}/0123456/access/Thumbs.db"
    FileUtils.touch(pathname)
    run_rectifier(fixture_pathname)
    assert(!File.exists?(pathname))
  end

  def test_access_masters_moved_into_top_level_bib_id_folder
    base = fixture_pathname
    FileUtils.mkdir_p("#{base}/access/accessMasters/0123456")
    FileUtils.touch("#{base}/access/accessMasters/0123456/0123456_001.jp2")
    FileUtils.touch("#{base}/access/accessMasters/0123456/0123456_key.jp2")
    FileUtils.touch("#{base}/access/accessMasters/0123456/0123456_title.jp2")
    run_rectifier(base)
    assert(!File.exists?("#{base}/access/accessMasters/0123456"))
    assert(File.exists?("#{base}/0123456/access/0123456_001.jp2"))
    assert(File.exists?("#{base}/0123456/access/0123456_key.jp2"))
    assert(File.exists?("#{base}/0123456/access/0123456_title.jp2"))
  end

  def test_preservation_masters_moved_into_top_level_bib_id_folder
    base = fixture_pathname
    FileUtils.mkdir_p("#{base}/preservation/preservationMasters/0123456")
    FileUtils.touch("#{base}/preservation/preservationMasters/0123456/0123456_001.tif")
    FileUtils.touch("#{base}/preservation/preservationMasters/0123456/0123456_key.tif")
    FileUtils.touch("#{base}/preservation/preservationMasters/0123456/0123456_title.tif")
    run_rectifier(base)
    assert(!File.exists?("#{base}/preservation/preservationMasters/0123456"))
    assert(File.exists?("#{base}/0123456/preservation/0123456_001.tif"))
    assert(File.exists?("#{base}/0123456/preservation/0123456_key.tif"))
    assert(File.exists?("#{base}/0123456/preservation/0123456_title.tif"))
  end

  def test_metadata_moved_into_metadata_folder
    base = fixture_pathname
    FileUtils.touch("#{base}/0123456/access/marc.xml")
    run_rectifier(base)
    assert(!File.exists?("#{base}/0123456/access/marc.xml"))
    assert(File.exists?("#{base}/0123456/metadata/marc.xml"))
  end

  def test_top_level_access_and_preservation_folders_deleted
    base = fixture_pathname
    FileUtils.mkdir_p("#{base}/access/accessMasters")
    FileUtils.mkdir_p("#{base}/preservation/preservationMasters")
    run_rectifier(base)
    assert(!File.exists?("#{base}/access"))
    assert(!File.exists?("#{base}/preservation"))
  end

  def test_jp2_folder_contents_moved_into_parent
    folder_pathname = "#{fixture_pathname}/0123456/access/jp2"
    file_pathname = "#{fixture_pathname}/0123456/access/jp2/bla.jp2"
    FileUtils.mkdir_p(folder_pathname)
    FileUtils.touch(file_pathname)
    run_rectifier(fixture_pathname)
    assert(File.exists?("#{fixture_pathname}/0123456/access/bla.jp2"))
  end

  def test_jp2_folders_deleted
    folder_pathname = "#{fixture_pathname}/0123456/access/jp2"
    FileUtils.mkdir(folder_pathname)
    run_rectifier(fixture_pathname)
    assert(!File.exists?(folder_pathname))
  end

  def test_tifs_converted_to_jp2s
    tif_pathname = "#{fixture_pathname}/0123456/access/bla.tif"
    jp2_pathname = "#{fixture_pathname}/0123456/access/bla.jp2"
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
