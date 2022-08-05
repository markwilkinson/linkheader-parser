# frozen_string_literal: true
require_relative '../../lib/linkheaders/processor'
require 'rest-client'


url1 = "https://w3id.org/a2a-fair-metrics/22-http-html-citeas-describedby-mixed/"
p = LinkHeaders::Processor.new(default_anchor: url1)
r = RestClient.get(url1)
p.extract_and_parse(response: r)
factory = p.factory  # LinkHeaders::LinkFactory


RSpec.describe LinkHeaders::Processor do

  it 'has a version number' do
    expect(LinkHeaders::Processor::VERSION).not_to be nil
  end

  it "should find PURL citeas which has described-by and cite-as in mixed HTTP and HTML headers" do
    expect(factory.all_links.length).to eq 5
  end
  it "should find find href on all links" do
    expect(factory.all_links.select{|l| l.href}.length).to eq 5
  end
  it "should find find href on all links" do
    expect(factory.all_links.select{|l| l.anchor}.length).to eq 5
  end
  it "should find 5 links in mixed HTTP and HTML headers" do
    expect(factory.all_links.select{|l| l.relation}.length).to eq 5
  end
  it "should find one citeas in mixed HTTP and HTML headers" do
    expect(factory.all_links.select{|l| l.relation == 'cite-as'}.length).to eq 1
  end
  it "should find described-by in mixed HTTP and HTML headers" do
    expect(factory.all_links.select{|l| l.relation == 'describedby'}.length).to eq 1
  end
end
