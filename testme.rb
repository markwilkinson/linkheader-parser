require_relative 'lib/linkset/parser'
require 'rest-client'

url = "https://s11.no/2022/a2a-fair-metrics/07-http-describedby-citeas-linkset-json/"
url = "https://s11.no/2022/a2a-fair-metrics/28-http-linkset-txt-only/"

p = Linkset::Parser.new(default_anchor: url)
r = RestClient.get(url)

factory = p.extract_and_parse(response: r)

factory.all_links.each  {|l| puts l.inspect; puts}

