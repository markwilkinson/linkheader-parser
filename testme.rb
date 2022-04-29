require_relative 'lib/linkheader/parser'
require 'rest-client'

url = "https://s11.no/2022/a2a-fair-metrics/07-http-describedby-citeas-linkset-json/"
url = "https://s11.no/2022/a2a-fair-metrics/28-http-linkset-txt-only/"

p = LinkHeader::Parser.new(default_anchor: url)
r = RestClient.get(url)

p.extract_and_parse(response: r)
factory = p.factory

factory.all_links.each  {|l| puts l.inspect; puts}

