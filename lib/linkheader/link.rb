module LinkHeader
  class LinkFactory

    # @return [<String>] the HTTP anchor used by default for implicit Links
    attr_accessor :default_anchor
    # @return [Array] An array of strings containing any warnings that were encountered when creating the link (e.g. duplicate cite-as but non-identical URLs)
    attr_accessor :warnings
    @@all_links = Array.new

    #
    # Create the LinkFacgtory Object
    #
    # @param [String] default_anchor The URL to be used as the default anchor for a link when it isn't specified
    #
    def initialize(default_anchor: 'https://example.org/')
      @default_anchor = default_anchor
      @warnings = Array.new
    end

    #
    # Create a new LinkHeader::Link object
    #
    # @param [Symbol] responsepart either :header, :body, or :linkset as the original location of this Link
    # @param [String] href the URL of the link
    # @param [String] relation the string of the relation type (e.g. "cite-as" or "described-by")
    # @param [String] anchor The URL of the anchor.  Defaults to the default anchor of the LinkHeader factory
    # @param [Hash] **kwargs All other facets of the link. e.g. 'type' => 'text/html',...
    #
    # @return [LinkHeader::Link] The Link object just created
    #
    def new_link(responsepart:, href:, relation:, anchor: @default_anchor, **kwargs)
      link = LinkHeader::Link.new(responsepart: responsepart, factory: self, href: href, anchor: anchor, relation: relation, **kwargs)
      sanitycheck(link)  # this will add warnings if the link already exists and has a conflict
      @@all_links |= [link]
      return link
    end

    #
    # retrieve all known LinkHeader::Link objects
    #
    # @return [Array] Array of all LinkHeader::Link objects created by the factory so far
    #
    def all_links
      @@all_links
    end

    #
    # Extracts Linkset type links from a list of LinkHeader::Link objects
    #
    # @return [Array] Array of LinkHeader::Link objects that represent URLs of LinkSets.
    #
    def linksets
      links = Array.new
      self.all_links.each do |link|
        # warn "found #{link.relation}"
        next unless link.relation == :linkset
        links << Link
      end
      return links
    end

    #
    # Extracts the LinkHeader::Link ojects that originated in the HTTP Headers
    #
    # @return [Array]  Array of LinkHeader::Link objects 
    #
    def headlinks
      links = Array.new
      self.all_links.each do |link|
        # warn "found #{link.relation}"
        next unless link.responsepart == :header
        links << Link
      end
      links
    end

    #
    # Extracts the LinkHeader::Link ojects that originated in the HTML Link Headers
    #
    # @return [Array]  Array of LinkHeader::Link objects
    #
    def bodylinks
      links = Array.new
      self.all_links.each do |link|
        # warn "found #{link.relation}"
        next unless link.responsepart == :body
        links << Link
      end
      links
    end

    #
    # Extracts the LinkHeader::Link ojects that originated from a LinkSet
    #
    # @return [Array]  Array of LinkHeader::Link objects
    #
    def linksetlinks
      links = Array.new
      self.all_links.each do |link|
        # warn "found #{link.relation}"
        next unless link.responsepart == :linkset
        links << Link
      end
      links
    end

    def sanitycheck(link)
      self.all_links.each do |l|
        if l.relation == "cite-as" and link.relation == "cite-as"
          if l.href != link.href
            @warnings << 'WARN: Found conflicting cite-as relations.  This should never happen'
          end
        end
        if l.href == link.href
          if l.relation != link.relation
            @warnings << 'WARN: Found identical hrefs with different relation types.  This may be suspicious. Both have been retained'
          end
        end
      end
    end
  end

  #
  # An LinkHeader::Link represnting an HTTP Link Header, an HTML LinkHeader, or a LinkSet Link.
  #
  class Link
    # @return [String] URL of the Link anchor
    attr_accessor :anchor 
    # @return [String] URL of the Link
    attr_accessor :href
    # @return [String] What is the relation? (e.g. "cite-as")
    attr_accessor :relation
    # @return [String] if the object is MIME-typed, what is the type?  (e.g. 'text/html')
    attr_accessor :type
    # @return [LinkHeader::LinkFactory] The factory that made the Link
    attr_accessor :factory
    # @return [Symbol] :header, :body, or :linkset indicating the place the Link object originated
    attr_accessor :responsepart

    #
    # Create the Link object
    #
    # @param [Symbol] responsepart :head, :body, :linkset
    # @param [LinkHeader::LinkFactory] factory the factory that made the link
    # @param [String] href The URL of the Link
    # @param [String] anchor The URL of the anchor
    # @param [String] relation the Link relation (e.g. "cite-as")
    # @param [hash] **kwargs The remaining facets of the link (e.g. type => 'text/html')
    #
    def initialize(responsepart:, factory:, href:, anchor:, relation:, **kwargs)
     
      @href = href
      @anchor = anchor
      @relation = relation
      @factory = factory
      @responsepart = responsepart

      kwargs.each do |k, v|
        define_singleton_method(k.to_sym) {
          value = instance_variable_get("@#{k}")
          return value
        } 
        define_singleton_method "#{k}=".to_sym do |val|
          instance_variable_set("@#{k}", val)
          return "@#{k}".to_sym
        end
      end
    end
  end
end