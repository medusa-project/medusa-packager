# Medusa Packager

This suite of scripts analyzes directory trees and processes them to bring them
into conformance with a given package profile.

[More information](https://uofi.app.box.com/notes/43514306333)

## Using on Windows

1. [Install Ruby 2.2.3](http://rubyinstaller.org)
2. From the command prompt (cmd.exe), `cd` into the Medusa Packager folder and
   run: `ruby map_package_analyzer.rb <path to analyze>`

   (To redirect the output to a log file instead of printing it in the terminal,
   append something like `> log.txt` to the command.)

## Using on Unix/OS X

1. Install RVM:

        gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
        \curl -sSL https://get.rvm.io | bash -s stable

2. Install Bundler: `gem install bundler`
3. `cd` into the Medusa Packager folder
4. Install the bundle: `bundle install`
5. Run the script: `ruby map_package_analyzer.rb <path to analyze>`

   (To redirect the output to a log file instead of printing it in the terminal,
   append something like `> log.txt` to the command.)
