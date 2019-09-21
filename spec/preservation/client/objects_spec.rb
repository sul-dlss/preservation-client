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

  describe '#checksums' do
    let(:path) { 'objects/checksums' }
    let(:druids) { ['oo000oo0000', 'oo111oo1111'] }
    let(:params) { { druids: druids, format: 'csv' } }

    context 'when API request succeeds' do
      let(:valid_csv_response) do
        <<~CSV
          druid:oo000oo0000,oo000oo0000_img_1.tif,ffc0cc90e4215e0a3d822b04a8eab980,d2703add746d7b6e2e5f8a73ef7c06b087b3fae5,6b66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527032f,4403882
          druid:oo000oo0000,oo000oo0000_img_2.tif,f59fabc1e08751bd30ad59caa8f35330,01d4b26c3d673bbedabccefb6817a89c6545ee59,a13ee152f9ac699d0c8304db01e1a6d34b5e4958640d38d591b2c341b56e7096,4297840
          druid:oo111oo1111,oo111oo1111_img_1.tif,f478a6833d9c369de7c6a0b48ca4d969,1b0038364418a93b4d1aae76ff60828558865eb1,90a7bd6b10341c953bd678d0faee60e874f9372a2d19481bcdd9b35190220d34,4530552
          druid:oo111oo1111,oo111oo1111_img_2.tif,e21b3a359d1a2b3a9d4bf70dd5cd22bf,7666672ef5510a6ae65ebb61f6433c9d3944ce4c,28c8fd263185edaf4358e38137150318ea80defae3893162f5be2d230502ca4a,4254270
        CSV
      end

      before do
        allow(subject).to receive(:post).with(path, params, 'checksums').and_return(valid_csv_response)
      end

      it 'returns the API response' do
        expect(subject.checksums(druids: druids)).to eq valid_csv_response
      end
    end

    context 'when API request fails' do
      let(:err_msg) { 'Mistakes were made.' }

      before do
        allow(subject).to receive(:post).with(path, params, 'checksums').and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
      end

      it 'raises an error' do
        expect { subject.checksums(druids: druids) }.to raise_error(Preservation::Client::UnexpectedResponseError, err_msg)
      end
    end
  end
end
