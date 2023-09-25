# frozen_string_literal: true
require_relative '../../lib/linkheaders/processor'
require 'rest-client'


url1 = "https://w3id.org/a2a-fair-metrics/22-http-html-citeas-describedby-mixed/"
p = LinkHeaders::Processor.new(default_anchor: url1)
r = RestClient.get(url1)
p.extract_and_parse(response: r)
factory = p.factory  # LinkHeaders::LinkFactory


RSpec.describe LinkHeaders::Processor do

  it 'Benchmark: has a version number' do
    expect(LinkHeaders::Processor::VERSION).not_to be nil
  end

  it "Benchmark: should find 8 links in total" do
    expect(factory.all_links.length).to eq 8
  end
  it "Benchmark: should find find href on all links" do
    expect(factory.all_links.select{|l| l.href}.length).to eq 8
  end
  it "Benchmark: should find find anchor on all links" do
    expect(factory.all_links.select{|l| l.anchor}.length).to eq 8
  end
  it "Benchmark: should find 5 links in mixed HTTP and HTML headers" do
    expect(factory.all_links.select{|l| l.relation}.length).to eq 8
  end
  it "Benchmark: should find one citeas in mixed HTTP and HTML headers" do
    expect(factory.all_links.select{|l| l.relation == 'cite-as'}.length).to eq 1
  end
  it "Benchmark: should find described-by in mixed HTTP and HTML headers" do
    expect(factory.all_links.select{|l| l.relation == 'describedby'}.length).to eq 1
  end

  url2 = "https://doi.org/10.7910/DVN/Z2JD58"
  p2 = LinkHeaders::Processor.new(default_anchor: url2)
  r2 = RestClient.get(url2)
  p2.extract_and_parse(response: r2)
  factory2 = p2.factory  # LinkHeaders::LinkFactory
  
  it "Dataverse: should find 29 links in total" do
    expect(factory2.all_links.length).to eq 28
  end
  it "Dataverse: should find find href on all links" do
    expect(factory2.all_links.select{|l| l.href}.length).to eq 28
  end
  it "Dataverse: should find find anchor on all links" do
    expect(factory2.all_links.select{|l| l.anchor}.length).to eq 28
  end
  it "Dataverse: should find one citeas" do
    expect(factory2.all_links.select{|l| l.relation == 'cite-as'}.length).to eq 1
  end
  it "Dataverse: should find 2 described-by" do
    expect(factory2.all_links.select{|l| l.relation == 'describedby'}.length).to eq 2
  end
  it "Dataverse: should find 1 license" do
    expect(factory2.all_links.select{|l| l.relation == 'license'}.length).to eq 1
  end


end
