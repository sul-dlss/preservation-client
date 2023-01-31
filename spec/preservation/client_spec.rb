# frozen_string_literal: true

RSpec.describe Preservation::Client do
  subject(:client) { described_class.configure(url: prez_url, token: auth_token) }

  let(:prez_url) { 'https://prezcat.example.com' }
  let(:auth_token) { 'my_secret_jwt_value' }

  it 'has a version number' do
    expect(Preservation::Client::VERSION).not_to be_nil
  end

  context 'when configured' do
    before do
      described_class.configure(url: prez_url, token: auth_token)
    end

    describe '.objects' do
      it 'returns an instance of Preservation::Client::Objects' do
        expect(described_class.objects).to be_instance_of Preservation::Client::Objects
      end

      it 'returns the memoized instance when called again' do
        first_time = described_class.objects
        expect(described_class.objects).to eq first_time
      end

      it 'uses default api version' do
        expect(described_class.objects.send(:api_version)).to eq described_class::DEFAULT_API_VERSION
      end
    end
  end

  describe '#configure' do
    it 'returns Client class' do
      expect(client).to eq described_class
    end

    it 'url is populated' do
      expect(client.instance.send(:url)).to eq prez_url
    end

    it 'auth token is populated' do
      expect(client.instance.send(:token)).to eq auth_token
    end

    it 'raises error if no url or token provided' do
      expect { described_class.configure }.to raise_error(ArgumentError, /missing keywords: :?url, :?token/)
    end

    it 'raises error if no url provided' do
      expect { described_class.configure(token: auth_token) }.to raise_error(ArgumentError, /missing keyword: :?url/)
    end

    it 'raises error if no token provided' do
      expect { described_class.configure(url: prez_url) }.to raise_error(ArgumentError, /missing keyword: :?token/)
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

  # NOTE: Unlike the other instance attrs tested above, read_timeout has
  #       different behavior (namely: defaulting instead of blowing up at
  #       configure time), so it is tested separately here
  describe '#read_timeout' do
    context 'when not configured' do
      it 'uses the default value' do
        expect(client.instance.send(:read_timeout)).to eq described_class::DEFAULT_TIMEOUT
      end
    end

    context 'when configured with override value' do
      subject(:client) { described_class.configure(url: prez_url, token: auth_token, read_timeout: read_timeout) }

      let(:read_timeout) { 6000 }

      it 'uses the supplied value' do
        expect(client.instance.send(:read_timeout)).to eq(read_timeout)
      end
    end

    context 'when configured with nil value' do
      subject(:client) { described_class.configure(url: prez_url, token: auth_token, read_timeout: nil) }

      it 'raises an error' do
        expect { client.instance.send(:read_timeout) }.to raise_error(described_class::Error, /read timeout has not been configured/)
      end
    end
  end
end
