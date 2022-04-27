ACCEPT_ALL_HEADER = {'Accept' => 'text/turtle, application/ld+json, application/rdf+xml, text/xhtml+xml, application/n3, application/rdf+n3, application/turtle, application/x-turtle, text/n3, text/turtle, text/rdf+n3, text/rdf+turtle, application/n-triples' }

TEXT_FORMATS = {
    'text' => ['text/plain',],
}

RDF_FORMATS = {
  'jsonld'  => ['application/ld+json', 'application/vnd.schemaorg.ld+json'],  # NEW FOR DATACITE
  'turtle'  => ['text/turtle','application/n3','application/rdf+n3',
               'application/turtle', 'application/x-turtle','text/n3','text/turtle',
               'text/rdf+n3', 'text/rdf+turtle'],
  #'rdfa'    => ['text/xhtml+xml', 'application/xhtml+xml'],
  'rdfxml'  => ['application/rdf+xml'],
  'triples' => ['application/n-triples','application/n-quads', 'application/trig']
}

XML_FORMATS = {
  'xml' => ['text/xhtml','text/xml',]
}

HTML_FORMATS = {
  'html' => ['text/html','text/xhtml+xml', 'application/xhtml+xml']
}

JSON_FORMATS = {
            'json' => ['application/json',]
}

