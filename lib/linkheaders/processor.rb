# frozen_string_literal: true

require_relative 'processor/version'
require_relative 'constants'
require_relative 'link'
require_relative 'web_utils'

require 'json'
require 'rest-client'
require 'securerandom'
require 'metainspector'

module LinkHeaders
  class Error < StandardError; end

  # A Link Header parser
  #
  # Works for both HTML and HTTP links, and handles references to Linksets of either JSON or Text types
  #
  class Processor
    # @return [<Type>] <description>
    attr_accessor :default_anchor, :factory

    #
    # Create the Link Headers Parser and its Link factory
    #
    # @param [<String>] default_anchor Link relations always have an anchor, but it is sometimes implicit.  This value will be used in implicit cases.
    #
    def initialize(default_anchor: 'https://default.anchor.org/')
      @default_anchor = default_anchor
      @factory = LinkHeaders::LinkFactory.new(default_anchor: @default_anchor)
    end

    #
    # Get the parser factory that contains all the links
    #
    # @return [<LinkHeader::LinkFactory>] The factory containing the links (LinkHeader::Link) that have been created so far
    #
    def factory
      @factory
    end

    #
    # Parses a RestClient::Response
    #
    # The HTTP headers are parsed for Links and if those links contain a Linkset, that is retrieved and parsed
    # If the Response is of some HTML form, this is also parsed for Link headers and Linkset links
    # All discovered links end up in a LinkHeader::LinkFactory object (self.factory)
    #
    # @param [<RestClilent::Response>] response The full response object from an HTTP 2** successful call
    #
    #
    def extract_and_parse(response: RestClient::Response.new)
      head = response.headers
      body = response.body
      # warn "\n\n head #{head.inspect}\n\n"

      unless head
        warn "WARNING: This doesn't seem to be a RestClient response message.\nReturning blank"
        return [[], []]
      end

      newlinks = parse_http_link_headers(head) # pass guid to check against anchors in linksets
      warn "HTTPlinks #{newlinks.inspect}"

      HTML_FORMATS['html'].each do |format|
        if head[:content_type] and head[:content_type].match(format)
          warn "found #{format} content - parsing"
          htmllinks = parse_html_link_headers(body) # pass html body to find HTML link headers
          warn "htmllinks #{htmllinks.inspect}"
        end
      end
    end

    #
    # Consume a String of the Link Headers and parse it into individual links. Will automatically retrieve and process any LinkSet references found.  All LinkHeader::Link objects end up in the LinkHeader::LinkFactory object (self.factory)
    #
    # @param [RestClient::Response::Header] headers  the Headers of a RestClent::Response.  Calls headers[:link] to retrieve '<https://example.one.com>; rel="preconnect", <https://example.two.com>; rel="preconnect",  <https://example.three.com>; rel="preconnect"'
    #
    #
    def parse_http_link_headers(headers)
      newlinks = Array.new
      # Link: <https://example.one.com>; rel="preconnect", <https://example.two.com>; rel="preconnect",  <https://example.three.com>; rel="preconnect"
      links = headers[:link]
      return [] unless links

      # warn links.inspect
      parts = links.split(',') # ["<https://example.one.com>; rel='preconnect'", "<https://example.two.com>; rel="preconnect"".....]
      # warn parts

      # Parse each part into a named link
      newlinks << split_http_link_headers_and_process(parts) # creates links from the split headers and adds to factory.all_links
      newlinks << check_for_linkset(responsepart: :header)  # all links are held in the Linkset::LinkFactory object (factory variable here).  This scans the links for a linkset link to follow
      newlinks
    end

    def split_http_link_headers_and_process(parts)
      newlinks = Array.new
      parts.each do |part, _index|
        # warn "link is:  #{part}"

        section = part.split(';') # ["<https://example.one.com>", "rel='preconnect'"]
        # warn section
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
        relations = relation.split(/\s+/)  # handle the multiple relation case
        $stderr.puts "RELATIONS #{relations}"

        relations.each do |rel|
          next unless rel.match?(/\w/)
          newlinks << factory.new_link(responsepart: :header, anchor: anchor, href: href, relation: rel, **sections) # parsed['https://example.one.com'][:rel] = "preconnect"
        end
      end
      newlinks
    end

    #
    # Parses the link headers out of an HTML body, and adds links to the LinkHeader::LinkFactory object.  Will automatically retrieve and process any LinkSet references found
    #
    # @param [String] body The HTML of the page containing HTML Link headers
    #
    def parse_html_link_headers(body)
      m = MetaInspector.new('http://example.org', document: body)
      # an array of elements that look like this: [{:rel=>"alternate", :type=>"application/ld+json", :href=>"http://scidata.vitk.lv/dataset/303.jsonld"}]
      newlinks = Array.new
      m.head_links.each do |l|
        warn "HTML head link is:  #{l.inspect}"
        next unless l[:href] and l[:rel] # required

        anchor = l[:anchor] || default_anchor
        l.delete(:anchor)
        relation = l[:rel]
        l.delete(:rel)
        href = l[:href]
        l.delete(:href)        
        
        relations = relation.split(/\s+/)  # handle the multiple relation case
        $stderr.puts "RELATIONS #{relations}"

        relations.each do |rel|
          next unless rel.match?(/\w/)
          newlinks << factory.new_link(responsepart: :header, anchor: anchor, href: href, relation: rel, **l) # parsed['https://example.one.com'][:rel] = "preconnect"
        end
      end
      newlinks << check_for_linkset(responsepart: :body)
      newlinks
    end

    def check_for_linkset(responsepart:)
      warn "looking for a linkset"
      newlinks = Array.new
      factory.linksets.each do |linkset|
        # warn "found #{linkset.methods- Object.new.methods}"
        # warn "inspect #{linkset.inspect}"
        next unless linkset.respond_to? 'type'
        # warn "responds #{linkset.type}  "
        case linkset.type
        when 'application/linkset+json'
          # warn "found a json linkset"
          newlinks << processJSONLinkset(href: linkset.href)
        when 'application/linkset'
          # warn "found a text linkset"
          newlinks << processTextLinkset(href:linkset.href)
        else
          warn "the linkset #{linkset} was not typed as 'application/linkset+json' or 'application/linkset', and it should be! (found #{linkset.type}) Ignoring..."
        end
      end
      newlinks
    end

    def processJSONLinkset(href:)
      _headers, linkset = fetch(href, { 'Accept' => 'application/linkset+json' })
      # warn "Linkset body #{linkset.inspect}"
      newlinks = Array.new
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
        # warn ls.inspect, "\n"
        anchor = ls['anchor'] || @default_anchor
        ls.delete('anchor') if ls['anchor'] # we need to delete since all others have a list as a value
        attrhash = {}
        # warn ls.keys, "\n"

        ls.each_key do |relation| # key =  e.g. "item", "described-by". "cite"
          # warn reltype, "\n"
          # warn ls[reltype], "\n"
          ls[relation].each do |attrs|  # attr = e.g.  {"href": "http://example.com/foo1", "type": "text/html"}
            next unless attrs['href']  # this is a required attribute of a  linkset relation

            href = attrs['href']
            # now go through the other attributes of that relation
            attrs.each do |attr, val| # attr = e.g. "type"; val = "text/html"
              attrhash[attr.to_sym] = val
            end
          end

          relations = relation.split(/\s+/)  # handle the multiple relation case

          relations.each do |rel|
            next unless rel.match?(/\w/)
            newlinks << factory.new_link(responsepart: :header, anchor: anchor, href: href, relation: rel, **attrhash) # parsed['https://example.one.com'][:rel] = "preconnect"
          end
        end
      end
      newlinks
    end

    def processTextLinkset(href:)
      newlinks = Array.new
      headers, linkset = fetch(href, { 'Accept' => 'application/linkset' })
      # warn "linkset body #{linkset.inspect}"
      return {} unless linkset

      links = linkset.scan(/(<.*?>[^<]+)/) # split on the open angle bracket, which indicates a new link
      # warn "Links found #{links}"

      links.each do |ls|
        # warn "workking on link #{ls}"
        ls = ls.first # ls is a single element array
        elements = ls.split(';') # semicolon delimited fields
        # ["<https://w3id.org/a2a-fair-metrics/08-http-describedby-citeas-linkset-txt/>", "anchor=\"https://s11.no/2022/a2a-fair-metrics/08-http-describedby-citeas-linkset-txt/\"", "rel=\"cite-as\""]
        href = elements.shift # first element is always the link url
        # warn "working on link href #{href}"
        href = href.match(/<([^>]+)>/)[1]
        attrhash = {}
        elements.each do |e|
          key, val = e.split('=')
          key.strip!
          val.strip!
          val.delete_prefix!('"').delete_suffix!('"') # get rid of newlines and start/end quotes
          attrhash[key.to_sym] = val # split on key=val and make key a symbol
        end 
        warn "No link relation type... this is bad!  Skipping" unless attrhash[:rel]
        next unless attrhash[:rel]
        relation = attrhash[:rel]
        attrhash.delete(:rel)
        anchor = attrhash[:anchor] || @default_anchor
        attrhash.delete(:anchor)
        
        relations = relation.split(/\s+/)  # handle the multiple relation case
        #$stderr.puts "RELATIONS #{relations}"
        relations.each do |rel|
          next unless rel.match?(/\w/)
          newlinks << factory.new_link(responsepart: :header, anchor: anchor, href: href, relation: rel, **attrhash) # parsed['https://example.one.com'][:rel] = "preconnect"
        end
      end
      newlinks
    end
  end
end
