# frozen_string_literal: true

RSpec.describe Preservation::Client::Catalog do
  let(:prez_api_url) { 'https://prezcat.example.com' }
  let(:auth_token) { 'my_secret_jwt_value' }

  before do
    Preservation::Client.configure(url: prez_api_url, token: auth_token)
  end

  let(:conn) { Preservation::Client.instance.send(:connection) }
  subject(:instance) { described_class.new(connection: conn) }
  let(:err_msg) { 'Mistakes were made.' }

  describe '#update' do
    let(:path) { "objects/#{druid}.json" }
    let(:druid) { 'bj102hs9687' }
    subject(:update) do
      instance.update(druid: druid,
                      version: version,
                      size: 2342,
                      storage_location: 'some/storage/location/from/endpoint/table')
    end

    let(:expected_body) do
      {
        'checksums_validated' => 'true', 'druid' => 'bj102hs9687',
        'incoming_size' => '2342', 'incoming_version' => version,
        'storage_location' => 'some/storage/location/from/endpoint/table'
      }
    end

    context 'when the request is successful' do
      context 'when the object is new (version == 1)' do
        let(:version) { 1 }

        context 'when API request succeeds' do
          before do
            stub_request(:post, 'https://prezcat.example.com/v1/catalog')
              .with(body: expected_body)
              .to_return(status: 200, body: '', headers: {})
          end

          it { is_expected.to be true }
        end

        context 'when API request fails' do
          before do
            stub_request(:post, 'https://prezcat.example.com/v1/catalog')
              .with(body: expected_body)
              .to_return(status: 500, body: '', headers: {})
          end

          it 'raises an error' do
            expect { update }.to raise_error(Preservation::Client::UnexpectedResponseError,
                                             'the server responded with status 500')
          end
        end

        context 'when API redirects' do
          before do
            stub_request(:post, 'https://prezcat.example.com/v1/catalog')
              .with(body: expected_body)
              .to_return(status: 301, body: '', headers: {})
          end

          it 'raises an error' do
            expect { update }.to raise_error(Preservation::Client::UnexpectedResponseError,
                                             'response was not successful. Received status 301')
          end
        end
      end

      context 'when the object exists in the catalog (version > 1)' do
        let(:version) { 2 }
        context 'when API request succeeds' do
          before do
            stub_request(:patch, 'https://prezcat.example.com/v1/catalog/bj102hs9687')
              .with(body: expected_body)
              .to_return(status: 200, body: '', headers: {})
          end

          it { is_expected.to be true }
        end

        context 'when API request fails' do
          before do
            stub_request(:patch, 'https://prezcat.example.com/v1/catalog/bj102hs9687')
              .with(body: expected_body)
              .to_return(status: 500, body: '', headers: {})
          end

          it 'raises an error' do
            expect { update }.to raise_error(Preservation::Client::UnexpectedResponseError, 'the server responded with status 500')
          end
        end
      end
    end
  end
end
