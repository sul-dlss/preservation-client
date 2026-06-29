# frozen_string_literal: true

require 'digest'
require 'tmpdir'

RSpec.describe Preservation::Client::Objects do
  let(:client) do
    described_class.new(connection: connection,
                        streaming_connection: streaming_connection,
                        retry_max: 3,
                        retry_interval: 0,
                        api_version: '')
  end

  let(:connection) { Preservation::Client.instance.send(:connection) }
  let(:streaming_connection) { Preservation::Client.instance.send(:streaming_connection) }
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

  describe '#object' do
    let(:path) { "objects/#{druid}.json" }
    let(:druid) { 'druid:oo000oo0000' }

    context 'when API request succeeds' do
      subject(:object) { client.object(druid) }

      let(:result_version) { 3 }
      let(:valid_response_body) do
        {
          druid: druid,
          current_version: result_version,
          ok_on_local_storage: false
        }
      end

      before do
        allow(client).to receive(:get_json).with(path, druid).and_return(valid_response_body)
      end

      it 'returns a Preservation::Client::Object' do
        expect(object).to be_an_instance_of(Preservation::Client::Object)
        expect(object.to_h).to eq valid_response_body
        expect(object.ok_on_local_storage?).to be false
      end
    end
  end

  describe '#current_version' do
    let(:path) { "objects/#{druid}.json" }
    let(:druid) { 'druid:oo000oo0000' }

    context 'when API request succeeds' do
      let(:result_version) { 3 }
      let(:valid_response_body) do
        {
          druid: druid,
          current_version: result_version,
          ok_on_local_storage: true
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

  describe '#content_to_file' do
    let(:source_filepath) { 'nested/content.pdf' }
    let(:downloaded_content) { "hello world\n" }

    def temp_download_files(dir)
      Dir.glob(File.join(dir, 'preservation-client-*.tmp'))
    end

    context 'when successful' do
      before do
        allow(client).to receive(:content) do |on_data:, **_kwargs|
          on_data.call('hello ', 6, nil)
          on_data.call("world\n", 12, nil)
        end
      end

      it 'writes streamed content and returns nil' do
        Dir.mktmpdir do |dir|
          destination = File.join(dir, 'download.pdf')

          client.content_to_file(druid: file_druid, filepath: source_filepath,
                                 destination_filepath: destination, version: '2')

          expect(File.read(destination)).to eq downloaded_content
          expect(temp_download_files(dir)).to be_empty
        end

        expect(client).to have_received(:content) do |druid:, filepath:, version:, **_kwargs|
          expect(druid).to eq file_druid
          expect(filepath).to eq source_filepath
          expect(version).to eq '2'
        end
      end
    end

    context 'when an existing destination file is present' do
      before do
        allow(client).to receive(:content) do |on_data:, **_kwargs|
          on_data.call(downloaded_content, downloaded_content.bytesize, nil)
        end
      end

      it 'atomically replaces an existing destination file' do
        Dir.mktmpdir do |dir|
          destination = File.join(dir, 'download.pdf')
          File.write(destination, 'old content')

          client.content_to_file(druid: file_druid, filepath: source_filepath, destination_filepath: destination)

          expect(File.read(destination)).to eq downloaded_content
        end
      end
    end

    context 'when expected_md5 is provided' do
      let(:expected_md5) { Digest::MD5.hexdigest(downloaded_content) }

      before do
        allow(client).to receive(:content) do |on_data:, **_kwargs|
          on_data.call(downloaded_content, downloaded_content.bytesize, nil)
        end
      end

      context 'when md5 matches' do
        it 'is successful' do
          Dir.mktmpdir do |dir|
            destination = File.join(dir, 'download.pdf')

            client.content_to_file(druid: file_druid, filepath: source_filepath,
                                   destination_filepath: destination,
                                   expected_md5: expected_md5)

            expect(File.read(destination)).to eq downloaded_content
          end
        end
      end
    end

    context 'when md5 does not match' do
      before do
        allow(client).to receive(:content) do |on_data:, **_kwargs|
          on_data.call(downloaded_content, downloaded_content.bytesize, nil)
        end
      end

      it 'raises IntegrityError on md5 mismatch and leaves destination unchanged' do
        Dir.mktmpdir do |dir|
          destination = File.join(dir, 'download.pdf')
          File.write(destination, 'existing destination')

          expect do
            client.content_to_file(druid: file_druid, filepath: source_filepath,
                                   destination_filepath: destination, expected_md5: 'wrongmd5')
          end.to raise_error(Preservation::Client::IntegrityError)

          expect(File.read(destination)).to eq 'existing destination'
          expect(temp_download_files(dir)).to be_empty
        end
      end
    end

    context 'when ConnectionFailedError' do
      before do
        @attempts = 0
        allow(client).to receive(:sleep)
        allow(client).to receive(:content) do |on_data:, **_kwargs|
          @attempts += 1
          raise Preservation::Client::ConnectionFailedError, 'timeout' if @attempts < 3 # rubocop:disable RSpec/InstanceVariable

          on_data.call(downloaded_content, downloaded_content.bytesize, nil)
        end
      end

      it 'retries and then succeeds' do
        Dir.mktmpdir do |dir|
          destination = File.join(dir, 'download.pdf')

          client.content_to_file(druid: file_druid, filepath: source_filepath,
                                 destination_filepath: destination, max: 3, interval: 0)

          expect(@attempts).to eq 3 # rubocop:disable RSpec/InstanceVariable
          expect(File.read(destination)).to eq downloaded_content
        end
      end
    end

    context 'when status is set on Preservation::Client::Error' do
      context 'when status is 5xx' do
        before do
          errors = [
            Preservation::Client::Error.new('server failure 1', status: 503),
            Preservation::Client::Error.new('server failure 2', status: 500)
          ]
          allow(client).to receive(:sleep)
          allow(client).to receive(:content) do |on_data:, **_kwargs|
            error = errors.shift
            raise error if error

            on_data.call(downloaded_content, downloaded_content.bytesize, nil)
          end
        end

        it 'retries on 5xx errors when status is set on Preservation::Client::Error' do
          Dir.mktmpdir do |dir|
            destination = File.join(dir, 'download.pdf')

            client.content_to_file(druid: file_druid, filepath: source_filepath,
                                   destination_filepath: destination, max: 3, interval: 0)

            expect(File.read(destination)).to eq downloaded_content
            expect(client).to have_received(:sleep).with(0.0).at_least(:once)
            expect(File.read(destination)).to eq downloaded_content
          end
        end
      end

      context 'when status is 4xx' do
        before do
          allow(client).to receive(:sleep)
          allow(client).to receive(:content).and_raise(Preservation::Client::Error.new('client failure', status: 404))
        end

        it 'does not retry on 4xx errors when status is set on Preservation::Client::Error' do
          Dir.mktmpdir do |dir|
            destination = File.join(dir, 'download.pdf')

            expect do
              client.content_to_file(druid: file_druid, filepath: source_filepath,
                                     destination_filepath: destination, max: 3, interval: 0)
            end.to raise_error(Preservation::Client::Error, 'client failure')

            expect(client).to have_received(:content).once
            expect(client).not_to have_received(:sleep)
          end
        end
      end

      context 'when retries are exhausted' do
        before do
          allow(client).to receive(:sleep)
          allow(client).to receive(:content).and_raise(Preservation::Client::ConnectionFailedError, 'network fail')
        end

        it 'removes temp files' do
          Dir.mktmpdir do |dir|
            destination = File.join(dir, 'download.pdf')

            expect do
              client.content_to_file(druid: file_druid, filepath: source_filepath,
                                     destination_filepath: destination, max: 1, interval: 0)
            end.to raise_error(Preservation::Client::ConnectionFailedError)

            expect(temp_download_files(dir)).to be_empty
            expect(File.exist?(destination)).to be false
          end
        end
      end
    end

    context 'when streaming is interrupted' do
      before do
        allow(client).to receive(:sleep)
        allow(client).to receive(:content) do |on_data:, **_kwargs|
          on_data.call('partial-bytes', 13, nil)
          raise Preservation::Client::ConnectionFailedError, 'stream interrupted'
        end
      end

      it 'does not overwrite destination' do
        Dir.mktmpdir do |dir|
          destination = File.join(dir, 'download.pdf')
          File.write(destination, 'safe destination')

          expect do
            client.content_to_file(druid: file_druid, filepath: source_filepath,
                                   destination_filepath: destination, max: 0, interval: 0)
          end.to raise_error(Preservation::Client::ConnectionFailedError)

          expect(File.read(destination)).to eq 'safe destination'
          expect(temp_download_files(dir)).to be_empty
        end
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
