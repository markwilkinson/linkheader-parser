# LinkHeaders::Processor

A gem to extract Link Headers from Web responses.

This module handles HTTP Link Headers, HTML Link Headers, and auto-follows links to LinkSets in both JSON and Text format, and processes them also.  It also handles some unusual cases, such as having multiple relation types in a single link, or when dealing with 204 or 410 response where there is no message body.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add linkheaders-processor

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install linkheaders-processor

## Usage


```

    require 'linkheaders/processor'
    require 'rest-client'

    # url1 has http link headers, and a reference to a linkset in json format
    url1 = "https://s11.no/2022/a2a-fair-metrics/07-http-describedby-citeas-linkset-json/"

    # url2 has http link headers, with a reference to a linkset in legacy text format
    url2 = "https://s11.no/2022/a2a-fair-metrics/28-http-linkset-txt-only/"

    p = LinkHeaders::Processor.new(default_anchor: url1)
    r = RestClient.get(url1)

    p.extract_and_parse(response: r)
    factory = p.factory  # LinkHeaders::LinkFactory

    factory.all_links.each do |l| 
        puts l.href
        puts l.relation
        puts l.responsepart

        # Additional properties are added as other instance methods
        # you can access them as follows:

        puts l.linkmethods  # returns list of instance methods beyond href and relation, that are attributes of the link
        l.linkmethods.each do |method|
            puts "#{method}=" + l.send(method)
        end
        # or
        puts l.type if l.respond_to? 'type'
        puts

    end



    p = LinkHeaders::Processor.new(default_anchor: url2)
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
