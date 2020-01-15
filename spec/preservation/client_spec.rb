# frozen_string_literal: true

RSpec.describe Preservation::Client do
  let(:prez_url) { 'https://prezcat.example.com' }
  let(:auth_token) { 'my_secret_jwt_value' }

  it 'has a version number' do
    expect(Preservation::Client::VERSION).not_to be nil
  end

  context 'once configured' do
    before do
      described_class.configure(url: prez_url, token: auth_token)
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
    subject(:client) { described_class.configure(url: prez_url, token: auth_token) }

    it 'returns Client class' do
      expect(client).to eq Preservation::Client
    end
    it 'url is populated' do
      expect(client.instance.send(:url)).to eq prez_url
    end
    it 'auth token is populated' do
      expect(client.instance.send(:token)).to eq auth_token
    end
    it 'raises error if no url or token provided' do
      expect { described_class.configure }.to raise_error(ArgumentError, /missing keywords: url, token/)
    end
    it 'raises error if no url provided' do
      expect { described_class.configure(token: auth_token) }.to raise_error(ArgumentError, /missing keyword: url/)
    end
    it 'raises error if no token provided' do
      expect { described_class.configure(url: prez_url) }.to raise_error(ArgumentError, /missing keyword: token/)
    end
    it 'connection is populated' do
      connection = client.instance.send(:connection)
      expect(connection).to be_instance_of(Faraday::Connection)
      expect(connection.url_prefix).to eq(URI(prez_url))
      expect(connection.headers).to include(
        'User-Agent' => "preservation-client #{Preservation::Client::VERSION}",
        'Authorization' => "Bearer #{auth_token}"
      )
    end
  end
end
