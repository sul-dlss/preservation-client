# frozen_string_literal: true

RSpec.describe Preservation::Client::VersionedApiService do
  let(:prez_api_url) { 'https://prezcat.example.com' }
  let(:druid) { 'oo000oo0000' }
  let(:faraday_err_msg) { 'faraday is sad' }

  before do
    Preservation::Client.configure(url: prez_api_url)
  end

  let(:conn) { Preservation::Client.instance.send(:connection) }
  let(:subject) { described_class.new(connection: conn, api_version: 'v6') }

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

  describe '#get' do
    let(:path) { 'my_path' }
    let(:params) { { foo: 'bar' } }
    let(:params_as_args) { 'foo=bar' }
    let(:api_version) { subject.send(:api_version) }

    it 'request url includes api_version when it is non-blank' do
      stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}?#{params_as_args}")
        .to_return(body: 'have api version', status: 200)
      expect(subject.send(:get, path, params)).to eq 'have api version'
    end
    it 'request url has no api_version when it is blank' do
      pc = described_class.new(connection: conn, api_version: '')
      stub_request(:get, "#{prez_api_url}/#{path}?#{params_as_args}").to_return(body: 'blank api version', status: 200)
      expect(pc.send(:get, path, params)).to eq 'blank api version'
    end

    context 'when response status success' do
      let(:resp_body) { "I'm a little teacup" }

      it 'returns response body' do
        stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}?#{params_as_args}")
          .to_return(body: resp_body, status: 200)
        expect(subject.send(:get, path, params)).to eq resp_body
      end
    end

    context 'when response status 404' do
      it 'raises Preservation::Client::NotFound with message from ResponseErrorFormatter' do
        stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}?#{params_as_args}").to_return(status: 404)
        expect { subject.send(:get, path, params) }.to raise_error(Preservation::Client::NotFoundError, /got 404/)
      end
    end

    context 'when response status is an error' do
      it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
        stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}?#{params_as_args}").to_return(status: 500)
        expect { subject.send(:get, path, params) }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 500/)
      end
    end

    context 'when response status is a redirect' do
      it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
        stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}?#{params_as_args}").to_return(status: 301)
        expect { subject.send(:get, path, params) }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 301/)
      end
    end
  end

  describe '#post' do
    let(:path) { 'my_path' }
    let(:druids) { ['oo000oo0000', 'oo111oo1111'] }
    let(:params) { { druids: druids } }
    let(:api_version) { subject.send(:api_version) }

    it 'request url includes api_version when it is non-blank' do
      stub_request(:post, "#{prez_api_url}/#{api_version}/#{path}").to_return(body: 'have api version', status: 200)
      expect(subject.send(:post, path, params)).to eq 'have api version'
    end
    it 'request url has no api_version when it is blank' do
      pc = described_class.new(connection: conn, api_version: '')
      stub_request(:post, "#{prez_api_url}/#{path}").to_return(body: 'blank api version', status: 200)
      expect(pc.send(:post, path, params)).to eq 'blank api version'
    end

    context 'when response status success' do
      let(:resp_body) { JSON.generate(foo: 'bar') }

      it 'returns response body' do
        stub_request(:post, "#{prez_api_url}/#{api_version}/#{path}").to_return(body: resp_body, status: 200)
        expect(subject.send(:post, path, params)).to eq resp_body
      end
    end

    context 'when response status 404' do
      it 'raises Preservation::Client::NotFound with message from ResponseErrorFormatter' do
        stub_request(:post, "#{prez_api_url}/#{api_version}/#{path}").to_return(status: 404)
        expect { subject.send(:post, path, params) }.to raise_error(Preservation::Client::NotFoundError, /got 404/)
      end
    end

    context 'when response status NOT success or 404' do
      it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
        stub_request(:post, "#{prez_api_url}/#{api_version}/#{path}").to_return(status: 500)
        expect { subject.send(:post, path, params) }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 500/)
      end
    end
  end
end
