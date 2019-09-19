# frozen_string_literal: true

RSpec.describe Preservation::Client::ResponseErrorFormatter do
  let(:druid) { 'oo666aa1234' }
  let(:method_name) { 'current_version' }
  let(:resp_status_msg) { 'Internal Server Error' }
  let(:resp_code) { 500 }
  let(:resp_body) { 'Something is terribly wrong' }
  let(:resp_env_url) { 'https://example.org/prezcat' }
  let(:resp_env) { instance_double(Faraday::Env, url: resp_env_url) }
  let(:response) { double(Faraday::Response, reason_phrase: resp_status_msg, status: resp_code, body: resp_body, env: resp_env) }

  subject(:formatter) { described_class.new(response: response, object_id: druid, client_method_name: method_name) }

  describe '.format' do
    let(:mock_instance) { double('mock instance') }

    it 'calls #format on a new instance' do
      allow(mock_instance).to receive(:format)
      allow(described_class).to receive(:new).with(response: response, object_id: nil, client_method_name: nil).and_return(mock_instance)
      described_class.format(response: response)
      expect(described_class).to have_received(:new).once
      expect(mock_instance).to have_received(:format).once
    end
  end

  describe '#initialize' do
    it 'populates status_msg attribute' do
      expect(formatter.status_msg).to eq(resp_status_msg)
    end

    it 'populates status_code attribute' do
      expect(formatter.status_code).to eq(resp_code)
    end

    it 'populates body attribute' do
      expect(formatter.body).to eq(resp_body)
    end

    it 'populates req_url attribute' do
      expect(formatter.req_url).to eq(resp_env_url)
    end

    it 'populates object_id attribute' do
      expect(formatter.object_id).to eq(druid)
    end

    it 'populates client_method_name attribute' do
      expect(formatter.client_method_name).to eq(method_name)
    end

    context 'with a blank body' do
      let(:response) { double('http response', reason_phrase: resp_status_msg, status: resp_code, body: '', env: resp_env) }

      it 'sets a default body attribute' do
        expect(formatter.body).to eq(described_class::DEFAULT_BODY)
      end
    end
  end

  describe '#format' do
    it 'formats an error message from attributes in the instance' do
      exp_msg = "Preservation::Client.#{method_name} for #{druid} got #{resp_status_msg} (#{resp_code}) from Preservation Catalog at #{resp_env_url}: #{resp_body}"
      expect(formatter.format).to eq(exp_msg)
    end

    context 'when an object id is not set' do
      subject(:formatter) { described_class.new(response: response, object_id: '', client_method_name: 'whatever') }

      it 'has sensible error message without object id' do
        exp_msg = "Preservation::Client.whatever got #{resp_status_msg} (#{resp_code}) from Preservation Catalog at #{resp_env_url}: #{resp_body}"
        expect(formatter.format).to eq(exp_msg)
      end
    end

    context 'when no reason_phrase' do
      let(:response) { double(Faraday::Response, reason_phrase: nil, status: resp_code, body: resp_body, env: resp_env) }

      it 'has sensible error message without reason_phrase id' do
        exp_msg = "Preservation::Client.#{method_name} for #{druid} got #{resp_code} from Preservation Catalog at #{resp_env_url}: #{resp_body}"
        expect(formatter.format).to eq(exp_msg)
      end
    end
  end
end
