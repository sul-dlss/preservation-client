# frozen_string_literal: true

RSpec.describe Preservation::Client::VersionedService do
  let(:prez_url) { 'https://prezcat.example.com' }

  before do
    Preservation::Client.configure(url: prez_url)
  end

  let(:conn) { Preservation::Client.instance.send(:connection) }
  let(:subject) { described_class.new(connection: conn, api_version: 'v6') }

  it 'populates api_version' do
    expect(subject.send(:api_version)).to eq 'v6'
  end
  it 'populates connection' do
    expect(subject.send(:connection)).to eq conn
  end
end
