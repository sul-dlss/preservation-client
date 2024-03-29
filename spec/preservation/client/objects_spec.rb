# frozen_string_literal: true

RSpec.describe Preservation::Client::Objects do
  let(:client) { described_class.new(connection: connection, api_version: '') }

  let(:connection) { Preservation::Client.instance.send(:connection) }
  let(:prez_api_url) { 'https://prezcat.example.com' }
  let(:auth_token) { 'my_secret_jwt_value' }
  let(:err_msg) { 'Mistakes were made.' }
  let(:manifest_filename) { 'signatureCatalog.xml' }
  let(:file_druid) { 'druid:oo000oo0000' }
  let(:file_api_path) { "objects/#{file_druid}/file" }
  let(:valid_prescat_content_diff_response) do
    <<-XML
      <fileInventoryDifference objectId="oo000oo0000" differenceCount="2" basis="v3-contentMetadata-all" other="new-contentMetadata-all" reportDatetime="2019-12-05T19:45:43Z">
        <fileGroupDifference groupId="content" differenceCount="2" identical="0" copyadded="0" copydeleted="0" renamed="0" modified="0" added="0" deleted="2">
          <subset change="deleted" count="2">
            <file change="deleted" basisPath="eric-smith-dissertation.pdf" otherPath="">
              <fileSignature size="1000217" md5="aead2f6f734355c59af2d5b2689e4fb3" sha1="22dc6464e25dc9a7d600b1de6e3848bf63970595" sha256=""/>
            </file>
            <file change="deleted" basisPath="eric-smith-dissertation-augmented.pdf" otherPath="">
              <fileSignature size="905566" md5="93802f1a639bc9215c6336ff5575ee22" sha1="32f7129a81830004f0360424525f066972865221" sha256=""/>
            </file>
          </subset>
          <subset change="identical" count="0"/>
          <subset change="copyadded" count="0"/>
          <subset change="copydeleted" count="0"/>
          <subset change="renamed" count="0"/>
          <subset change="modified" count="0"/>
          <subset change="added" count="0"/>
        </fileGroupDifference>
      </fileInventoryDifference>
    XML
  end

  before do
    Preservation::Client.configure(url: prez_api_url, token: auth_token)
  end

  describe '#current_version' do
    let(:path) { "objects/#{druid}.json" }
    let(:druid) { 'druid:oo000oo0000' }

    context 'when API request succeeds' do
      let(:result_version) { 3 }
      let(:valid_response_body) do
        {
          id: 666,
          druid: druid,
          current_version: result_version,
          created_at: '2019-09-06T13:01:29.076Z',
          updated_at: '2019-09-15T13:01:29.076Z',
          preservation_policy_id: 1
        }
      end

      before do
        allow(client).to receive(:get_json).with(path, druid).and_return(valid_response_body)
      end

      it 'returns the current version as an integer' do
        expect(client.current_version(druid)).to eq result_version
      end
    end

    context 'when API request fails' do
      before do
        allow(client).to receive(:get_json).with(path, druid).and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
      end

      it 'raises an error' do
        expect { client.current_version(druid) }.to raise_error(Preservation::Client::UnexpectedResponseError, err_msg)
      end
    end
  end

  describe '#content_inventory_diff' do
    let(:druid) { 'oo000oo0000' }
    let(:path) { "objects/#{druid}/content_diff" }
    let(:content_md) { '<contentMetadata>yer stuff here</contentMetadata>' }
    let(:params) { { druid: druid, content_metadata: content_md } }
    let(:api_params) { { subset: 'all', version: nil }.merge(params.except(:druid)) }

    context 'when API request succeeds' do
      before do
        allow(client).to receive(:post).with(path, api_params).and_return(valid_prescat_content_diff_response)
      end

      it 'returns the API response as a Moab::FileInventoryDifference' do
        result = client.content_inventory_diff(**params)
        expect(result).to be_an_instance_of(Moab::FileInventoryDifference)
        expect(result.digital_object_id).to eq 'oo000oo0000'
        expect(result.difference_count).to eq 2
        expect(client).to have_received(:post).with(path, api_params)
      end

      it 'requests the API response for specified subset' do
        params[:subset] = 'publish'
        api_params[:subset] = 'publish'
        client.content_inventory_diff(**params)
        expect(client).to have_received(:post).with(path, api_params)
      end

      it 'requests the API response for specified version' do
        params[:version] = '3'
        api_params[:version] = '3'
        client.content_inventory_diff(**params)
        expect(client).to have_received(:post).with(path, api_params)
      end
    end

    context 'when API request fails' do
      before do
        allow(client).to receive(:post).with(path, api_params).and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
      end

      it 'raises an error' do
        expect { client.content_inventory_diff(**params) }.to raise_error(Preservation::Client::UnexpectedResponseError, err_msg)
      end
    end
  end

  describe '#shelve_content_diff' do
    let(:druid) { 'oo000oo0000' }
    let(:path) { "objects/#{druid}/content_diff" }
    let(:content_md) { '<contentMetadata>yer stuff here</contentMetadata>' }
    let(:params) { { druid: druid, content_metadata: content_md } }
    let(:api_params) { { content_metadata: content_md, subset: 'shelve', version: nil } }

    context 'when API request succeeds' do
      before do
        allow(client).to receive(:post).with(path, api_params).and_return(valid_prescat_content_diff_response)
      end

      it 'returns a Moab::FileGroupDifference for subset shelve' do
        result = client.shelve_content_diff(**params)
        expect(result).to be_an_instance_of(Moab::FileGroupDifference)
        expect(result.group_id).to eq 'content'
        expect(result.difference_count).to eq 2
        expect(api_params[:subset]).to eq 'shelve'
        expect(client).to have_received(:post).with(path, api_params)
      end
    end

    context 'when API request fails' do
      before do
        allow(client).to receive(:post).with(path, api_params).and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
      end

      it 'raises an error' do
        expect { client.shelve_content_diff(**params) }.to raise_error(Preservation::Client::UnexpectedResponseError, err_msg)
      end
    end
  end

  describe '#checksum' do
    context 'when API request succeeds' do
      let(:valid_json_response) do
        [{
          'filename' => 'oo000oo0000_img_1.tif',
          'md5' => 'ffc0cc90e4215e0a3d822b04a8eab980',
          'sha1' => 'd2703add746d7b6e2e5f8a73ef7c06b087b3fae5',
          'sha256' => '6b66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527032f',
          'filesize' => '4403882'
        }]
      end

      before do
        allow(client).to receive(:get_json).with('objects/oo000oo0000/checksum', 'oo000oo0000').and_return(valid_json_response)
      end

      it 'returns the API response' do
        expect(client.checksum(druid: 'oo000oo0000')).to eq valid_json_response
      end
    end

    context 'when API request fails' do
      before do
        allow(client).to receive(:get_json).with('objects/oo000oo0000/checksum', 'oo000oo0000').and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
      end

      it 'raises an error' do
        expect { client.checksum(druid: 'oo000oo0000') }.to raise_error(Preservation::Client::UnexpectedResponseError, err_msg)
      end
    end
  end

  describe '#content' do
    let(:filename) { 'content.pdf' }
    let(:file_api_params) do
      {
        category: 'content',
        filepath: filename,
        version: nil
      }
    end

    context 'when API request succeeds' do
      let(:valid_response_body) do
        File.read("spec/fixtures/#{filename}")
      end

      before do
        allow(client).to receive(:get).and_return(valid_response_body)
      end

      it 'returns the content file' do
        expect(client.content(druid: file_druid, filepath: filename)).to eq valid_response_body
      end

      it 'returns the content file for specified version' do
        allow(client).to receive(:get).and_return(valid_response_body)
        expect(client.content(druid: file_druid, filepath: filename, version: '6')).to eq valid_response_body
      end
    end

    context 'when API request fails' do
      before do
        allow(client).to receive(:get).and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
      end

      it 'raises an error' do
        expect { client.content(druid: file_druid, filepath: filename) }.to raise_error(Preservation::Client::UnexpectedResponseError, err_msg)
      end
    end
  end

  describe '#manifest' do
    let(:file_api_params) do
      {
        category: 'manifest',
        filepath: manifest_filename,
        version: nil
      }
    end

    context 'when API request succeeds' do
      let(:valid_response_body) do
        <<-XML
          <!-- byte and blockCount are off, but irrelevant -->
          <signatureCatalog objectId="druid:zz555zz5555" versionId="2" catalogDatetime="2016-06-14T21:59:49Z" fileCount="1" byteCount="1953086" blockCount="1924">
            <entry originalVersion="1" groupId="content" storagePath="eric-smith-dissertation-augmented.pdf">
              <fileSignature size="905566" md5="93802f1a639bc9215c6336ff5575ee22" sha1="32f7129a81830004f0360424525f066972865221" sha256="a67276820853ddd839ba614133f1acd7330ece13f1082315d40219bed10009de"/>
            </entry>
          </signatureCatalog>
        XML
      end

      before do
        allow(client).to receive(:get).and_return(valid_response_body)
      end

      it 'returns the manifest file' do
        expect(client.manifest(druid: file_druid, filepath: manifest_filename)).to eq valid_response_body
      end

      it 'returns the manifest file for specified version' do
        expect(client.manifest(druid: file_druid, filepath: manifest_filename, version: '6')).to eq valid_response_body
      end
    end

    context 'when API request fails' do
      before do
        allow(client).to receive(:get).and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
      end

      it 'raises an error' do
        expect { client.manifest(druid: file_druid, filepath: manifest_filename) }.to raise_error(Preservation::Client::UnexpectedResponseError, err_msg)
      end
    end
  end

  describe '#metadata' do
    let(:metadata_filename) { 'identityMetadata.xml' }
    let(:file_api_params) do
      {
        category: 'metadata',
        filepath: metadata_filename,
        version: nil
      }
    end

    context 'when API request succeeds' do
      let(:valid_response_body) do
        <<-XML
        <identityMetadata>
          <sourceId source="sul">PC0170_s3_4th_of_July_2010-07-04_095432_0003</sourceId>
          <objectId>druid:oo000oo0000</objectId>
          <objectCreator>DOR</objectCreator>
          <objectLabel>some label</objectLabel>
          <objectType>item</objectType>
        </identityMetadata>
        XML
      end

      before do
        allow(client).to receive(:get).and_return(valid_response_body)
      end

      it 'returns the metadata file' do
        expect(client.metadata(druid: file_druid, filepath: metadata_filename)).to eq valid_response_body
      end

      it 'returns the metadata file for specified version' do
        allow(client).to receive(:get).and_return(valid_response_body)
        expect(client.metadata(druid: file_druid, filepath: metadata_filename, version: '6')).to eq valid_response_body
      end
    end

    context 'when API request fails' do
      before do
        allow(client).to receive(:get).and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
      end

      it 'raises an error' do
        expect { client.metadata(druid: file_druid, filepath: metadata_filename) }.to raise_error(Preservation::Client::UnexpectedResponseError, err_msg)
      end
    end
  end

  describe '#validate_moab' do
    subject(:request) { client.validate_moab(druid: druid) }

    let(:druid) { 'oo000oo0000' }

    context 'when API request succeeds' do
      before do
        stub_request(:get, "https://prezcat.example.com/objects/#{druid}/validate_moab")
          .to_return(status: 200, body: 'ok', headers: {})
      end

      it 'returns ok' do
        expect(request).to eq 'ok'
      end
    end

    context 'when API request fails with object not found' do
      before do
        stub_request(:get, "https://prezcat.example.com/objects/#{druid}/validate_moab")
          .to_return(status: 404, headers: {})
      end

      it 'raises an error' do
        expect { request }.to raise_error(Preservation::Client::NotFoundError)
      end
    end
  end

  describe '#signature_catalog' do
    let(:file_api_params) do
      {
        category: 'manifest',
        filepath: manifest_filename,
        version: nil
      }
    end

    context 'when API request succeeds' do
      let(:valid_response_body) do
        <<-XML
          <!-- byte and blockCount are off, but irrelevant -->
          <signatureCatalog objectId="druid:zz555zz5555" versionId="2" catalogDatetime="2016-06-14T21:59:49Z" fileCount="1" byteCount="1953086" blockCount="1924">
            <entry originalVersion="1" groupId="content" storagePath="eric-smith-dissertation-augmented.pdf">
              <fileSignature size="905566" md5="93802f1a639bc9215c6336ff5575ee22" sha1="32f7129a81830004f0360424525f066972865221" sha256="a67276820853ddd839ba614133f1acd7330ece13f1082315d40219bed10009de"/>
            </entry>
          </signatureCatalog>
        XML
      end

      before do
        allow(client).to receive(:get).and_return(valid_response_body)
      end

      it 'returns the signature catalog file' do
        expect(client.signature_catalog(file_druid).to_xml).to eq Moab::SignatureCatalog.parse(valid_response_body).to_xml
      end
    end

    context 'when API request fails' do
      before do
        allow(client).to receive(:get).and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
      end

      it 'if 404 status, raise NotFoundError' do
        errmsg_not_found = "Preservation::Client.signature_catalog for #{file_druid} got 404 File Not Found (404) from Preservation ..."
        allow(client).to receive(:get).and_raise(Preservation::Client::NotFoundError, errmsg_not_found)
        expect { client.signature_catalog(file_druid) }.to raise_error(Preservation::Client::NotFoundError, errmsg_not_found)
      end

      it 'if not 404 status, raise UnexpectedResponseError' do
        allow(client).to receive(:get).and_raise(Preservation::Client::UnexpectedResponseError, err_msg)
        expect { client.signature_catalog(file_druid) }.to raise_error(Preservation::Client::UnexpectedResponseError, err_msg)
      end
    end
  end
end
