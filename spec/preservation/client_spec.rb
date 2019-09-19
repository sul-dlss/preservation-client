# frozen_string_literal: true

RSpec.describe Preservation::Client do
  let(:prez_url) { 'https://prezcat.example.com' }
  it 'has a version number' do
    expect(Preservation::Client::VERSION).not_to be nil
  end

  context 'once configured' do
    before do
      described_class.configure(url: prez_url)
    end

    describe '.objects' do
      it 'returns an instance of Client::Objects' do
        expect(described_class.objects).to be_instance_of Preservation::Client::Objects
      end

      it 'returns the memoized instance when called again' do
        expect(described_class.objects).to eq described_class.objects
      end

      it 'uses default api version' do
        expect(described_class.objects.send(:api_version)).to eq described_class::DEFAULT_API_VERSION
      end
    end
  end

  describe '#configure' do
    subject(:client) { described_class.configure(url: prez_url) }

    it 'returns Client class' do
      expect(client).to eq Preservation::Client
    end
    it 'url is populated' do
      expect(client.instance.send(:url)).to eq prez_url
    end
    it 'raises error if no url provided' do
      expect { described_class.configure }.to raise_error(ArgumentError, /missing keyword: url/)
    end
    it 'connection is populated' do
      expect(client.instance.send(:connection)).to be_instance_of(Faraday::Connection)
    end
  end
end
