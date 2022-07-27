# frozen_string_literal: true

RSpec.describe LinkHeader::Parser do
  it 'has a version number' do
    expect(LinkHeader::Parser::VERSION).not_to be nil
  end
end
