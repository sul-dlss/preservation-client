# frozen_string_literal: true

RSpec.describe Preservation::Client::Catalog do
  subject(:instance) { described_class.new(connection: conn) }

  let(:prez_api_url) { 'https://prezcat.example.com' }
  let(:conn) { Preservation::Client.instance.send(:connection) }
  let(:err_msg) { 'Mistakes were made.' }
  let(:auth_token) { 'my_secret_jwt_value' }

  before do
    Preservation::Client.configure(url: prez_api_url, token: auth_token)
  end

  describe '#update' do
    subject(:update) do
      instance.update(druid: druid,
                      version: version,
                      size: 2342,
                      storage_location: 'some/storage/location/from/endpoint/table')
    end

    let(:path) { "objects/#{druid}.json" }
    let(:expected_body) do
      {
        'druid' => 'bj102hs9687',
        'incoming_version' => version,
        'incoming_size' => 2342,
        'storage_location' => 'some/storage/location/from/endpoint/table',
        'checksums_validated' => true
      }.to_json
    end
    let(:expected_headers) do
      {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization' => 'Bearer my_secret_jwt_value',
        'Content-Type' => 'application/json',
        'User-Agent' => "preservation-client #{Preservation::Client::VERSION}"
      }
    end
    let(:druid) { 'bj102hs9687' }

    context 'when the request is successful' do
      context 'when the object is new (version == 1)' do
        let(:version) { 1 }

        context 'when API request succeeds' do
          before do
            stub_request(:post, 'https://prezcat.example.com/v1/catalog')
              .with(body: expected_body, headers: expected_headers)
              .to_return(status: 200, body: '', headers: {})
          end

          it { is_expected.to eq '' }
        end

        context 'when API request fails' do
          before do
            stub_request(:post, 'https://prezcat.example.com/v1/catalog')
              .with(body: expected_body, headers: expected_headers)
              .to_return(status: 500, body: 'ActiveRecord::ConnectionNotEstablished', headers: {})
          end

          it 'raises an error' do
            expect { update }.to raise_error(Preservation::Client::UnexpectedResponseError,
                                             %r{got 500 from Preservation at v1/catalog: ActiveRecord::ConnectionNotEstablished})
          end
        end

        context 'when API redirects' do
          before do
            stub_request(:post, 'https://prezcat.example.com/v1/catalog')
              .with(body: expected_body, headers: expected_headers)
              .to_return(status: 301, body: '', headers: {})
          end

          it 'raises an error' do
            expect { update }.to raise_error(Preservation::Client::UnexpectedResponseError,
                                             %r{got 301 from Preservation at https://prezcat.example.com/v1/catalog})
          end
        end
      end

      context 'when the object exists in the catalog (version > 1)' do
        let(:version) { 2 }

        context 'when API request succeeds' do
          before do
            stub_request(:patch, 'https://prezcat.example.com/v1/catalog/bj102hs9687')
              .with(body: expected_body, headers: expected_headers)
              .to_return(status: 200, body: '', headers: {})
          end

          it { is_expected.to eq '' }
        end

        context 'when API request fails' do
          before do
            stub_request(:patch, 'https://prezcat.example.com/v1/catalog/bj102hs9687')
              .with(body: expected_body, headers: expected_headers)
              .to_return(status: 500, body: 'ActiveRecord::ConnectionNotEstablished', headers: {})
          end

          it 'raises an error' do
            expect { update }.to raise_error(Preservation::Client::UnexpectedResponseError, %r{got 500 from Preservation at v1/catalog/bj102hs9687: ActiveRecord::ConnectionNotEstablished})
          end
        end
      end
    end
  end
end
