# frozen_string_literal: true

require_relative 'parser/version'
require_relative 'constants'
require_relative 'link'

require 'json'
require 'rest-client'
require 'securerandom'
require 'metainspector'

module Linkset
  class Error < StandardError; end

  class Parser
    attr_accessor :default_anchor, :factory

    def initialize(default_anchor: 'https://default.anchor.org/')
      @default_anchor = default_anchor
      @factory = Linkset::LinkFactory.new(default_anchor: @default_anchor)
    end

    def extract_and_parse(response: RestClient::Response.new)
      head = response.headers
      body = response.body
      # warn "\n\n head #{head.inspect}\n\n"

      unless head
        warn "WARNING: This doesn't seem to be a RestClient response message.\nReturning blank"
        return [[], []]
      end

      parse_http_link_headers(head) # pass guid to check against anchors in linksets
      HTML_FORMATS['html'].each do |format|
        if head[:content_type] and head[:content_type].match(format)
          htmllinks = parse_html_link_elements(body) # pass html body to find HTML link headers
        end
      end
      return self.factory
    end

    def parse_http_link_headers(headers)
      # Link: <https://example.one.com>; rel="preconnect", <https://example.two.com>; rel="preconnect",  <https://example.three.com>; rel="preconnect"
      links = headers[:link]
      return [] unless links

      # $stderr.puts links.inspect
      parts = links.split(',') # ["<https://example.one.com>; rel='preconnect'", "<https://example.two.com>; rel="preconnect"".....]
      # $stderr.puts parts

      # Parse each part into a named link
      split_http_link_headers(parts) # creates links from the split headers and adds to factory.all_links
      check_for_linkset(responsepart: :header)
    end

    def split_http_link_headers(parts)
      parts.each do |part, _index|
        section = part.split(';') # ["<https://example.one.com>", "rel='preconnect'"]
        # $stderr.puts section
        next unless section[0]

        href = section[0][/<(.*)>/, 1]
        next unless section[1]

        sections = {}
        section[1..].each do |s| # can be more than one link property "rel='preconnect'"
          s.strip!
          unless m = s.match(%r{(\w+?)="?([\w:\d.,\#\-+/\s]+)"?})
            next
          end # can be rel="cite-as describedby"  --> two relations in one!  or "linkset+json"

          relation = m[1] # rel"
          value = m[2] # "preconnect"
          sections[relation] = value # value could hold multiple relation types   sections[:rel] = "preconnect"
        end
        next unless sections['rel']  # the relation is required!

        anchor = sections['anchor'] || default_anchor
        sections.delete('anchor')
        relation = sections['rel']
        sections.delete('rel')

        factory.new_link(responsepart: :header, anchor: anchor, href: href, relation: relation, **sections) # parsed['https://example.one.com'][:rel] = "preconnect"
      end
      factory
    end

    def parse_html_link_elements(body)
      m = MetaInspector.new('http://example.org', document: body)
      # an array of elements that look like this: [{:rel=>"alternate", :type=>"application/ld+json", :href=>"http://scidata.vitk.lv/dataset/303.jsonld"}]

      m.head_links.each do |l|
        next unless l[:href] and l[:rel]  # required
        anchor = l[:anchor] || self.default_anchor
        l.delete(:anchor)
        relation = l[:rel]
        l.delete(:rel)
        href = l[:href]
        l.delete(:href)
        factory.new_link(responsepart: :body, anchor: anchor, href: href, relation: relation, **l) 
      end
      check_for_linkset(responsepart: :body)
    end

    def check_for_linkset(responsepart:) 

      self.factory.linksets.each do |linkset|
        case linkset.type
        when 'application/linkset+json'
          processJSONLinkset(linkset.href, responsepart)
        when 'application/linkset'
          processTextLinkset(link.href, responsepart)
        else
          warn "the linkset #{linkset} was not typed as 'application/linkset+json' or 'application/linkset', and it should be!  Ignoring..."
        end
      end
    end

    def processJSONLinkset(href, responsepart)
      headers, linkset = fetch(href, { 'Accept' => 'application/linkset+json' })
      # warn headers.inspect
      # warn linkset.inspect

      return nil unless linkset

      # linkset = '{ "linkset":
      #   [
      #     { "anchor": "http://example.net/bar",
      #       "item": [
      #         {"href": "http://example.com/foo1", "type": "text/html"},
      #         {"href": "http://example.com/foo2"}
      #       ],
      #       "next": [
      #         {"href": "http://the.next/"}
      #       ]
      #     }
      #   ]
      # }'

      linkset = JSON.parse(linkset)
      linkset['linkset'].each do |ls|
        #warn ls.inspect, "\n"
        anchor = ls['anchor'] || link
        ls.delete('anchor') if ls['anchor'] # we need to delete since all others have a list as a value
        attrhash = {}
        parsed[anchor] = {}
        #warn ls.keys, "\n"

        ls.keys.each do |reltype| # key =  e.g. "item", "described-by". "cite"
          # warn reltype, "\n"
          # warn ls[reltype], "\n"
          ls[reltype].each do |relation|  # relation = e.g.  {"href": "http://example.com/foo1", "type": "text/html"}
            next unless relation['href']  # this is a required attribute of a  linkset relation

            href = relation['href']

            # relation.delete('href')
            # now go through the other attributes of that relation
            relation.each do |attr, val| # attr = e.g. "type"; val = "text/html"
              attrhash[attr.to_sym] = val
            end
            link = lsfactory.new_link(responsepart: responsepart, href: href, relation: reltype, anchor: anchor, **attrhash)

            # parsed[anchor].merge!({ linkurl => { reltype.to_sym => attrhash } })
          end
        end
      end
    end

    def processTextLinkset(link, _anchor)
      parsed = {}
      _headers, linkset = fetch(link, { 'Accept' => 'application/linkset' })
      # $stderr.puts "headers #{headers.inspect}"
      return {} unless linkset

      links = linkset.scan(/(<.*?>[^<]+)/) # split on the open angle bracket, which indicates a new link

      links.each do |ls|
        ls = ls.first # ls is a single element array
        elements = ls.split(';') # semicolon delimited fields
        # ["<https://w3id.org/a2a-fair-metrics/08-http-describedby-citeas-linkset-txt/>", "anchor=\"https://s11.no/2022/a2a-fair-metrics/08-http-describedby-citeas-linkset-txt/\"", "rel=\"cite-as\""]
        href = elements.shift # first element is always the link url
        href = href.match(/<([^>]+)>/)[1]
        linkshash = {}
        elements.each do |e|
          key, val = e.split('=')
          key.strip!
          val.strip!
          val.delete_prefix!('"').delete_suffix!('"') # get rid of newlines and start/end quotes
          linkshash[key.to_sym] = val # split on key=val and make key a symbol
        end

        # $stderr.puts "linkshash #{linkshash}\n#{linkshash[:anchor]}\n#{anchor}\n\n"
        # next unless linkshash[:anchor] and linkshash[:anchor] == anchor # eliminate the ones we don't want
        parsed[href] = linkshash
      end
      parsed
    end
  end
end
