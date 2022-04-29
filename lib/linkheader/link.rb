module LinkHeader
  class LinkFactory
    attr_accessor :default_anchor, :warnings
    @@all_links = Array.new

    def initialize(default_anchor: 'https://example.org/')
      @default_anchor = default_anchor
      @warnings = Array.new
    end

    def new_link(responsepart:, href:, relation:, anchor: @default_anchor, **kwargs)
      link = LinkHeader::Link.new(responsepart: responsepart, factory: self, href: href, anchor: anchor, relation: relation, **kwargs)
      sanitycheck(link)  # this will add warnings if the link already exists and has a conflict
      @@all_links |= [link]
      return link
    end

    def all_links
      @@all_links
    end

    def linksets
      links = Array.new
      self.all_links.each do |link|
        # warn "found #{link.relation}"
        next unless link.relation == :linkset
        links << Link
      end
      return links
    end

    def headlinks
      links = Array.new
      self.all_links.each do |link|
        # warn "found #{link.relation}"
        next unless link.responsepart == :header
        links << Link
      end
      return links
    end

    def bodylinks
      links = Array.new
      self.all_links.each do |link|
        # warn "found #{link.relation}"
        next unless link.responsepart == :body
        links << Link
      end
      return links
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

  class Link
    attr_accessor :anchor, :href, :relation, :type, :factory, :responsepart

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
