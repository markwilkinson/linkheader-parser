require 'linkheader/processor'
#require_relative 'lib/linkheader/processor'
require 'rest-client'

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

