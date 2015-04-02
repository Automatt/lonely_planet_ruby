# Atlas

## Ruby coding exercise

This is simple file processor that will output a directory of html files based on an xml file of destinations and corresponding file of taxonomy.

Usage: `ruby atlas.rb taxonomy.xml destinations.xml output_dir`

## Requirements

- Ruby 2.0 or greater (tested with 2.1.1p76)
- The only gem needed is Nokogiri.  You can use `bundle install` if you need this.

## Features

- Single file for simplicity
- Uses simple classes for extensibility
- No modifications to example template

## Improvements to make

- More intentional ordering of content sections
- Putting classes in individual files in /lib would be more ideomatic for Rails
- Add RSpec tests for classes
