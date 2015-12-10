# Medusa Packager

This suite of scripts analyzes directory trees and processes them to bring them
into conformance with a given package profile.

[More information](https://uofi.app.box.com/notes/43514306333)

## Usage

### Windows

1. [Install Ruby 2.2.3](http://rubyinstaller.org)
2. From the command prompt (cmd.exe), `cd` into the Medusa Packager folder and
   run: `ruby map_package_analyzer.rb <path to analyze>`

   (To redirect the output to a log file instead of printing it in the terminal,
   append something like `> log.txt` to the command.)

### Unix/OS X

1. Install RVM:

        gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
        \curl -sSL https://get.rvm.io | bash -s stable

2. Install Bundler: `gem install bundler`
3. `cd` into the Medusa Packager folder
4. Install the bundle: `bundle install`
5. Run the script: `ruby map_package_analyzer.rb <path to analyze>`

   (To redirect the output to a log file instead of printing it in the terminal,
   append something like `> log.txt` to the command.)

## Workflow

### Updating Metadata

1. Update the source metadata in Excel
2. Export to CSV
3. Run the collection-specific `process.rb` script, with the destination
   pathname of the package, to generate LRP AIP XML files from it in the
   correct structure
4. Re-index the collection in
   [PearTree](https://github.com/medusa-project/PearTree) with
   `bundle exec rake peartree:index[/pathname/of/collection]`

### Validating Packages

Use the `map_package_analyzer.rb` script to check packages for errors.

## Notes

* Text files should have CRLF line endings for platform-interoperability.
