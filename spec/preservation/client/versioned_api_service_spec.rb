# frozen_string_literal: true

RSpec.describe Preservation::Client::VersionedApiService do
  let(:prez_api_url) { 'https://prezcat.example.com' }
  let(:druid) { 'oo000oo0000' }
  let(:caller_method_name) { 'my_method_name' }
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
      expect(subject.send(:get_json, path, druid, caller_method_name)).to eq JSON.parse(resp_body)
    end
    it 'request url has no api_version when it is blank' do
      pc = described_class.new(connection: conn, api_version: '')
      resp_body = JSON.generate(bar: 'blank api version')
      stub_request(:get, "#{prez_api_url}/#{path}").to_return(body: resp_body, status: 200)
      expect(pc.send(:get_json, path, druid, caller_method_name)).to eq JSON.parse(resp_body)
    end

    context 'when response status success' do
      let(:resp_body) { JSON.generate(foo: 'bar') }

      it 'returns response body' do
        stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}").to_return(body: resp_body, status: 200)
        expect(subject.send(:get_json, path, druid, caller_method_name)).to eq JSON.parse(resp_body)
      end
    end

    context 'when response status NOT success' do
      it '404 status code' do
        stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}").to_return(status: 404)
        exp_msg = "#{druid} not found in Preservation at #{prez_api_url}/#{api_version}/#{path}"
        expect { subject.send(:get_json, path, druid, caller_method_name) }.to raise_error(Preservation::Client::NotFoundError, exp_msg)
      end
      it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
        stub_request(:get, "#{prez_api_url}/#{api_version}/#{path}").to_return(status: 500)
        expect { subject.send(:get_json, path, druid, caller_method_name) }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 500/)
      end
    end

    context 'when Faraday::ResourceNotFound raised' do
      it 'raises Preservation::Client::NotFoundError' do
        allow(conn).to receive(:get).and_raise(Faraday::ResourceNotFound, faraday_err_msg)
        exp_err_msg = "HTTP GET to #{prez_api_url}/#{api_version}/#{path} failed with #{Faraday::ResourceNotFound}: #{faraday_err_msg}"
        expect { subject.send(:get_json, path, druid, caller_method_name) }.to raise_error(Preservation::Client::NotFoundError, exp_err_msg)
      end
    end

    context 'when Faraday::ParsingError raised' do
      it 'raises Preservation::Client::UnexpectedResponseError' do
        allow(conn).to receive(:get).and_raise(Faraday::ParsingError, faraday_err_msg)
        exp_err_msg = "HTTP GET to #{prez_api_url}/#{api_version}/#{path} failed with #{Faraday::ParsingError}: #{faraday_err_msg}"
        expect { subject.send(:get_json, path, druid, caller_method_name) }.to raise_error(Preservation::Client::UnexpectedResponseError, exp_err_msg)
      end
    end

    context 'when Faraday::RetriableResponse raised' do
      it 'raises Preservation::Client::UnexpectedResponseError' do
        allow(conn).to receive(:get).and_raise(Faraday::RetriableResponse, faraday_err_msg)
        exp_err_msg = "HTTP GET to #{prez_api_url}/#{api_version}/#{path} failed with #{Faraday::RetriableResponse}: #{faraday_err_msg}"
        expect { subject.send(:get_json, path, druid, caller_method_name) }.to raise_error(Preservation::Client::UnexpectedResponseError, exp_err_msg)
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
      expect(subject.send(:post, path, params, caller_method_name)).to eq 'have api version'
    end
    it 'request url has no api_version when it is blank' do
      pc = described_class.new(connection: conn, api_version: '')
      stub_request(:post, "#{prez_api_url}/#{path}").to_return(body: 'blank api version', status: 200)
      expect(pc.send(:post, path, params, caller_method_name)).to eq 'blank api version'
    end

    context 'when response status success' do
      let(:resp_body) { JSON.generate(foo: 'bar') }

      it 'returns response body' do
        stub_request(:post, "#{prez_api_url}/#{api_version}/#{path}").to_return(body: resp_body, status: 200)
        expect(subject.send(:post, path, params, caller_method_name)).to eq resp_body
      end
    end

    context 'when response status NOT success' do
      it 'raises Preservation::Client::UnexpectedResponseError with message from ResponseErrorFormatter' do
        stub_request(:post, "#{prez_api_url}/#{api_version}/#{path}").to_return(status: 500)
        expect { subject.send(:post, path, params, caller_method_name) }.to raise_error(Preservation::Client::UnexpectedResponseError, /got 500/)
      end
    end

    context 'when Faraday::ResourceNotFound raised' do
      it 'raises Preservation::Client::NotFoundError' do
        allow(conn).to receive(:post).and_raise(Faraday::ResourceNotFound, faraday_err_msg)
        exp_err_msg = "HTTP POST to #{prez_api_url}/#{path} failed with #{Faraday::ResourceNotFound}: #{faraday_err_msg}"
        expect { subject.send(:post, path, params, caller_method_name) }.to raise_error(Preservation::Client::NotFoundError, exp_err_msg)
      end
    end

    context 'when Faraday::ParsingError raised' do
      it 'raises Preservation::Client::UnexpectedResponseError' do
        allow(conn).to receive(:post).and_raise(Faraday::ParsingError, faraday_err_msg)
        exp_err_msg = "HTTP POST to #{prez_api_url}/#{path} failed with #{Faraday::ParsingError}: #{faraday_err_msg}"
        expect { subject.send(:post, path, params, caller_method_name) }.to raise_error(Preservation::Client::UnexpectedResponseError, exp_err_msg)
      end
    end

    context 'when Faraday::RetriableResponse raised' do
      it 'raises Preservation::Client::UnexpectedResponseError' do
        allow(conn).to receive(:post).and_raise(Faraday::RetriableResponse, faraday_err_msg)
        exp_err_msg = "HTTP POST to #{prez_api_url}/#{path} failed with #{Faraday::RetriableResponse}: #{faraday_err_msg}"
        expect { subject.send(:post, path, params, caller_method_name) }.to raise_error(Preservation::Client::UnexpectedResponseError, exp_err_msg)
      end
    end
  end
end
