# frozen_string_literal: true

RSpec.describe Preservation::Client::VersionedApiService do
  subject(:service) { described_class.new(connection: conn, api_version: 'v6') }

  let(:auth_token) { 'my_secret_jwt_value' }
  let(:conn) { Preservation::Client.instance.send(:connection) }
  let(:druid) { 'oo000oo0000' }
  let(:faraday_err_msg) { 'faraday is sad' }
  let(:prez_api_url) { 'https://prezcat.example.com' }

  before do
    Preservation::Client.configure(url: prez_api_url, token: auth_token)
  end

  it 'populates api_version' do
    expect(subject.send(:api_version)).to eq 'v6'
  end

  it 'populates connection' do
    expect(subject.send(:connection)).to eq conn
  end

  describe '#get_json' do
    let(:path) { 'my_path' }
    let(:api_version) { subject.send(:api_version) }

    it 'request url includes api_version when it is non-blank' do
      resp_body = JSON.generate(foo: 'have api version')
      stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}").to_return(body: resp_body, status: 200)
      expect(subject.send(:get_json, path, druid)).to eq JSON.parse(resp_body)
    end

    it 'request url has no api_version when it is blank' do
      pc = described_class.new(connection: conn, api_version: '')
      resp_body = JSON.generate(bar: 'blank api version')
      stub_request(:get, "#{prez_api_url}/#{path}").to_return(body: resp_body, status: 200)
      expect(pc.send(:get_json, path, druid)).to eq JSON.parse(resp_body)
    end

    context 'when response status success' do
      let(:resp_body) { JSON.generate(foo: 'bar') }

      it 'returns response body' do
        stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}").to_return(body: resp_body, status: 200)
        expect(subject.send(:get_json, path, druid)).to eq JSON.parse(resp_body)
      end
    end

    context 'when response is 404' do
      it 'raises Preservation::Client::NotFoundError' do
        stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}").to_return(status: 404)
        exp_msg = "#{druid} not found in Preservation at #{prez_api_url}/#{api_version}/#{path}"
        expect { subject.send(:get_json, path, druid) }.to raise_error(Preservation::Client::NotFoundError, exp_msg)
      end
    end

    context 'when response is 301' do
      it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
        stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}").to_return(status: 301)
        expect { subject.send(:get_json, path, druid) }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 301/)
      end
    end
  end

  describe '#delete' do
    subject(:delete) { service.send(:delete, 'my_path', foo: 'bar') }

    let(:status) { 200 }
    let(:resp_body) { nil }

    before do
      stub_request(:delete, 'https://prezcat.example.com/v6/my_path?foo=bar').to_return(status: status, body: resp_body)
    end

    context 'when it is successful' do
      let(:resp_body) { "I'm a little teacup" }

      it { is_expected.to eq resp_body }
    end

    context 'when response status 404' do
      let(:status) { 404 }

      it 'raises Preservation::Client::NotFound with message from ResponseErrorFormatter' do
        expect { delete }.to raise_error(Preservation::Client::NotFoundError, /got 404/)
      end
    end

    context 'when response status is an error' do
      let(:status) { 500 }

      it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
        expect { delete }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 500/)
      end
    end

    context 'when response status is a redirect' do
      let(:status) { 301 }

      it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
        expect { delete }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 301/)
      end
    end
  end

  describe '#get' do
    subject(:get) { service.send(:get, 'my_path', { foo: 'bar' }, on_data: nil) }

    let(:status) { 200 }
    let(:resp_body) { nil }

    before do
      stub_request(:get, 'https://prezcat.example.com/v6/my_path?foo=bar').to_return(status: status, body: resp_body)
    end

    context 'when it is successful' do
      let(:resp_body) { "I'm a little teacup" }

      it { is_expected.to eq resp_body }
    end

    context 'when response status 404' do
      let(:status) { 404 }

      it 'raises Preservation::Client::NotFound with message from ResponseErrorFormatter' do
        expect { get }.to raise_error(Preservation::Client::NotFoundError, /got 404/)
      end
    end

    context 'when response status is an error' do
      let(:status) { 500 }

      it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
        expect { get }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 500/)
      end
    end

    context 'when response status is a redirect' do
      let(:status) { 301 }

      it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
        expect { get }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 301/)
      end
    end

    context 'when streaming' do
      subject(:get) { service.send(:get, 'my_path', { foo: 'bar' }, on_data: callback) }

      let(:callback) { proc { |data, _count| buffer << data } }
      let(:buffer) { [] }
      let(:resp_body) { "I'm a little teacup" }

      it 'streams' do
        get
        expect(buffer).to eq ["I'm a little teacup"]
      end
    end
  end

  describe 'HTTP actions with bodies' do
    %i[patch post put].each do |method|
      describe "##{method}" do
        let(:api_version) { subject.send(:api_version) }
        let(:druids) { ['oo000oo0000', 'oo111oo1111'] }
        let(:params) { { druids: druids } }
        let(:path) { 'my_path' }

        it 'request url includes api_version when it is non-blank' do
          stub_request(method, "#{prez_api_url}/#{api_version}/#{path}").to_return(body: 'have api version', status: 200)
          expect(subject.send(method, path, params)).to eq 'have api version'
        end

        it 'request url has no api_version when it is blank' do
          pc = described_class.new(connection: conn, api_version: '')
          stub_request(method, "#{prez_api_url}/#{path}").to_return(body: 'blank api version', status: 200)
          expect(pc.send(method, path, params)).to eq 'blank api version'
        end

        it 'request sends params in body and content-type in header' do
          pc = described_class.new(connection: conn, api_version: '')
          stub_request(method, "#{prez_api_url}/#{path}")
            .with(body: params.to_json, headers: { 'Content-Type' => 'application/json' })
            .to_return(body: 'blank api version', status: 200)
          expect(pc.send(method, path, params)).to eq 'blank api version'
        end

        context 'when response status is 200' do
          let(:resp_body) { JSON.generate(foo: 'bar') }

          it 'returns response body' do
            stub_request(method, "#{prez_api_url}/#{api_version}/#{path}").to_return(body: resp_body, status: 200)
            expect(subject.send(method, path, params)).to eq resp_body
          end
        end

        context 'when response status is 404' do
          it 'raises Preservation::Client::NotFound with message from ResponseErrorFormatter' do
            stub_request(method, "#{prez_api_url}/#{api_version}/#{path}").to_return(status: 404)
            expect { subject.send(method, path, params) }.to raise_error(Preservation::Client::NotFoundError, /got 404/)
          end
        end

        context 'when response status is neither 200 or 404' do
          it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
            stub_request(method, "#{prez_api_url}/#{api_version}/#{path}").to_return(status: 500)
            expect { subject.send(method, path, params) }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 500/)
          end
        end
      end
    end
  end
end
