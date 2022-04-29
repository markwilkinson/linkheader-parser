# LinkHeader::Parser

A gem to extract Link Headers from Web responses.

This module handles HTTP Link Headers, HTML Link Headers, and auto-follows links to LinkSets in both JSON and Text format, and processes them also.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add linkheader-parser

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install linkheader-parser

## Usage

    require 'linkheader/parser'
    require 'rest-client'

    ur11 = "https://s11.no/2022/a2a-fair-metrics/07-http-describedby-citeas-linkset-json/"
    url2 = "https://s11.no/2022/a2a-fair-metrics/28-http-linkset-txt-only/"

    parser = LinkHeader::Parser.new(default_anchor: url1)
    response = RestClient.get(url1)

    parser.extract_and_parse(response: response)
    factory = parser.factory

    factory.all_links.each  {|l| puts l.inspect; puts}

    parser = LinkHeader::Parser.new(default_anchor: url2)
    response = RestClient.get(url2)

    parser.extract_and_parse(response: response)
    factory = parser.factory

    factory.all_links.each  {|l| puts l.inspect; puts}


## Development


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/markwilkinson/linkheader-parser.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
