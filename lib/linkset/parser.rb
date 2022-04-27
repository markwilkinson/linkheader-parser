# frozen_string_literal: true

require_relative "parser/version"
require_relative "constants"

require "json"
require "rest-client"
require "securerandom"

module Linkset
  class Error < StandardError; end
  class Parser
    def initialize
      
    end

    def extract_and_parse(response: RestClient::Respose.new())
      head, body = response.header, response.body
      $stderr.puts "\n\n head #{head.inspect}\n\n"
      
      if !head
          $stderr.puts "WARNING: This doesn't seem to be a RestClient response message.\nReturning blank"
          return [[], []]
      end

      httplinks = parse_http_link_headers(head)  # pass guid to check against anchors in linksets
      htmllinks = Hash.new
      HTML_FORMATS['html'].each do |format|
          if head[:content_type] and head[:content_type].match(format)
              htmllinks = parse_html_link_elements(body, guid) # pass guid to check against anchors in linksets
          end
      end
      return [httplinks, htmllinks]

    end

    def parse_http_link_headers(headers)

      # Link: <https://example.one.com>; rel="preconnect", <https://example.two.com>; rel="preconnect",  <https://example.three.com>; rel="preconnect"
      parsed = Hash.new
      links = headers[:link]
      return [] unless links
      #$stderr.puts links.inspect
      parts = links.split(',') # ["<https://example.one.com>; rel='preconnect'", "<https://example.two.com>; rel="preconnect"".....]
      #$stderr.puts parts
      
      # Parse each part into a named link
      parsed = split_http_link_headers(parts, parsed)  # returns parsed['https://example.one.com'][:rel] = "preconnect"
      # $stderr.puts "\n\nPRE-PARSED\n\n #{parsed}"
      parsed = check_for_linkset(parsed)
      return parsed
    end

    def split_http_link_headers(parts, parsed)
      parts.each do |part, _index|
        section = part.split(';')  # ["<https://example.one.com>", "rel='preconnect'"]
        #$stderr.puts section
        next unless section[0]
        link = section[0][/<(.*)>/,1]
        #$stderr.puts url
        next unless section[1]
        type = ""
        sections = Hash.new
        section[1..].each do |s|  # can be more than one link property "rel='preconnect'"
            s.strip!
            if m = s.match(/([\w]+?)="?([\w\:\d\.\,\#\-\+\/\s]+)"?/)  # can be rel="cite-as describedby"  --> two relations in one!  or "linkset+json"
                type = m[1]  # rel"
                value = m[2] # "preconnect"
                sections[type.to_sym] = value  # value could hold multiple relation types   sections[:rel] = "preconnect"
            end
        end        
        parsed[link] = sections  # parsed['https://example.one.com'][:rel] = "preconnect"
      end
      return parsed
    end


    def parse_html_link_elements(body, anchor)
        links = Hash.new        
        m = MetaInspector.new("http://example.org", document: body)
        #an array of elements that look like this: [{:rel=>"alternate", :type=>"application/ld+json", :href=>"http://scidata.vitk.lv/dataset/303.jsonld"}]
    
        m.head_links.each do |l|
            link = l[:href]
            next unless link
            links[link] = l
        end
        links = ApplesUtils::check_for_linkset(links, anchor)
        return links
    end



    def check_for_linkset(parsed) # incoming: {"http://link1.org" => {:sectiontype1 => value, :sectiontype2 => value2}}
      #$stderr.puts "\n\nPARSED\n\n #{parsed}"
      reparsed = Hash.new
      parsed.each do |link,  valhash|
        # $stderr.puts valhash
        next unless valhash[:rel] == 'linkset'
        if valhash[:type] == 'application/linkset+json'
          linksethash = processJSONLinkset(link)
          $stderr.puts "\n\nlinksethash\n\n #{linksethash}"
          reparsed = parsed.merge(linksethash)
          # $stderr.puts parsed
        elsif valhash[:type] == 'application/linkset'
          linksethash = processTextLinkset(link)
          $stderr.puts "\n\nlinksethash\n\n #{linksethash}"
          reparsed = parsed.merge(linksethash)
        end
      end
      $stderr.puts "\n\nREPARSED\n\n #{reparsed}"
      return reparsed.any? ? reparsed : parsed
    end


    def processJSONLinkset(link)
      parsed = Hash.new
      # headers, linkset = fetch(link,{'Accept' => 'application/linkset+json'})
      # $stderr.puts headers.inspect
      # $stderr.puts linkset.inspect
      
      # return {} unless linkset

      linkset = '{ "linkset":
        [
          { "anchor": "http://example.net/bar",
            "item": [
              {"href": "http://example.com/foo1", "type": "text/html"},
              {"href": "http://example.com/foo2"}
            ],
            "next": [
              {"href": "http://the.next/"}
            ]
          }
        ]
      }'
      linkset = JSON.parse(linkset)
      linkset['linkset'].each do |ls|
        $stderr.puts ls.inspect, "\n"
        anchor = ls['anchor'] ? ls['anchor'] : SecureRandom.uuid
        ls.delete('anchor') if  ls['anchor']
        attrhash = Hash.new
        parsed[anchor] = Hash.new
        $stderr.puts ls.keys, "\n"

        ls.keys.each do |reltype|  # key =  e.g. "item", "described-by". "cite"
          $stderr.puts reltype, "\n"
          $stderr.puts ls[reltype], "\n"
          ls[reltype].each do |relation|  # relation = e.g.  {"href": "http://example.com/foo1", "type": "text/html"}
            next unless relation["href"]  # this is a required attribute of a  linkset relation
            linkurl = relation["href"]
            relation.delete('href')
            # now go through the other attributes of that relation
            relation.each do |attr, val|  # attr = e.g. "type"; val = "text/html"
              attrhash[attr.to_sym] = val;
            end
            parsed[anchor].merge!({linkurl => {reltype.to_sym => attrhash}})
          end
        end
      end
      return parsed
    end

    def processTextLinkset(link, anchor)
      parsed = Hash.new
      _headers, linkset = fetch(link,{'Accept' => 'application/linkset'})
      # $stderr.puts "headers #{headers.inspect}"
      return {} unless linkset
      links = linkset.scan(/(\<.*?\>[^\<]+)/)  # split on the open angle bracket, which indicates a new link

      links.each do |ls|
        ls = ls.first  # ls is a single element array
        elements = ls.split(';')  # semicolon delimited fields
        # ["<https://w3id.org/a2a-fair-metrics/08-http-describedby-citeas-linkset-txt/>", "anchor=\"https://s11.no/2022/a2a-fair-metrics/08-http-describedby-citeas-linkset-txt/\"", "rel=\"cite-as\""] 
        href = elements.shift  # first element is always the link url
        href = href.match(/\<([^\>]+)\>/)[1]
        linkshash = Hash.new
        elements.each do |e| 
          key, val = e.split('=')
          key.strip!
          val.strip!
          val.delete_prefix!('"').delete_suffix!('"')  # get rid of newlines and start/end quotes
          linkshash[key.to_sym] = val # split on key=val and make key a symbol
        end  
        
        # $stderr.puts "linkshash #{linkshash}\n#{linkshash[:anchor]}\n#{anchor}\n\n"
        # next unless linkshash[:anchor] and linkshash[:anchor] == anchor # eliminate the ones we don't want
        parsed[href] = linkshash
      end
      return parsed
    end

  end
end
