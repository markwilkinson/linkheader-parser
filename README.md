# LinkHeader::Parser

A gem to extract Link Headers from Web responses.

This module handles HTTP Link Headers, HTML Link Headers, and auto-follows links to LinkSets in both JSON and Text format, and processes them also.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add linkheader-processor

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install linkheader-processor

## Usage

```

require 'linkheader/processor'
require 'rest-client'

# these two URLs return linksets in the newer json format, and the old text format

url1 = "https://s11.no/2022/a2a-fair-metrics/07-http-describedby-citeas-linkset-json/"
url2 = "https://s11.no/2022/a2a-fair-metrics/28-http-linkset-txt-only/"

p = LinkHeader::Parser.new(default_anchor: url1)
r = RestClient.get(url1)

p.extract_and_parse(response: r)
factory = p.factory

factory.all_links.each do |l| 
    puts l.href
    puts l.relation
    puts l.responsepart
    puts
    puts
end



p = LinkHeader::Parser.new(default_anchor: url2)
r = RestClient.get(url2)

p.extract_and_parse(response: r)
factory = p.factory

factory.all_links.each do |l| 
    puts l.href
    puts l.relation
    puts l.responsepart
    puts
    puts
end

```


## Development


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/markwilkinson/linkheader-parser.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
