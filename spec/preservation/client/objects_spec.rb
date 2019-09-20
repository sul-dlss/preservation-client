# frozen_string_literal: true

RSpec.describe Preservation::Client::Objects do
  let(:prez_api_url) { 'https://prezcat.example.com' }

  before do
    Preservation::Client.configure(url: prez_api_url)
  end

  let(:conn) { Preservation::Client.instance.send(:connection) }
  let(:subject) { described_class.new(connection: conn, api_version: '') }

  describe '#current_version' do
    let(:path) { "objects/#{druid}.json" }

    context 'when API request succeeds' do
      let(:result_version) { 3 }
      let(:valid_response) do
        {
          'id': 666,
          'druid': druid,
          'current_version': result_version,
          'created_at': '2019-09-06T13:01:29.076Z',
          'updated_at': '2019-09-15T13:01:29.076Z',
          'preservation_policy_id': 1
        }
      end

      before do
        allow(subject).to receive(:get_json).with(path, druid, 'current_version').and_return(valid_response)
      end

      context 'with full druid' do
        let(:druid) { 'druid:oo000oo0000' }

        it 'returns the current version as an integer' do
          expect(subject.current_version(druid)).to eq result_version
        end
      end

      context 'with bare druid' do
        let(:druid) { 'oo000oo0000' }

        it 'returns the current version as an integer' do
          expect(subject.current_version(druid)).to eq result_version
        end
      end
    end

    context 'when API request fails' do
      let(:err_msg) { 'Mistakes were made.' }
      let(:druid) { 'oo000oo0000' }

      before do
        allow(subject).to receive(:get_json).with(path, druid, 'current_version').and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
      end

      it 'raises an error' do
        expect { subject.current_version(druid) }.to raise_error(Preservation::Client::UnexpectedResponseError, err_msg)
      end
    end
  end
end
