# frozen_string_literal: true

RSpec.describe Preservation::Client::ResponseErrorFormatter do
  subject(:formatter) { described_class.new(response: response, object_id: druid, client_method_name: method_name) }

  let(:druid) { 'oo666aa1234' }
  let(:method_name) { 'current_version' }
  let(:resp_status_msg) { 'Internal Server Error' }
  let(:resp_code) { 500 }
  let(:resp_body) { 'Something is terribly wrong' }
  let(:resp_env_url) { 'https://example.org/prezcat' }
  let(:resp_env) { instance_double(Faraday::Env, url: resp_env_url) }
  let(:response) { instance_double(Faraday::Response, reason_phrase: resp_status_msg, status: resp_code, body: resp_body, env: resp_env) }

  describe '.format' do
    let(:mock_instance) { instance_double(described_class) }

    it 'calls #format on a new instance' do
      allow(mock_instance).to receive(:format)
      allow(described_class).to receive(:new).with(response: response, object_id: nil, client_method_name: nil).and_return(mock_instance)
      described_class.format(response: response)
      expect(mock_instance).to have_received(:format).once
    end
  end

  describe '#initialize' do
    context 'with a blank body' do
      let(:response) { instance_double(Faraday::Response, reason_phrase: resp_status_msg, status: resp_code, body: '', env: resp_env) }

      it 'sets a default body attribute' do
        expect(formatter.send(:body)).to eq(described_class::DEFAULT_BODY)
      end
    end
  end

  describe '#format' do
    it 'formats an error message from attributes in the instance' do
      exp_msg = "Preservation::Client.#{method_name} for #{druid} got #{resp_status_msg} (#{resp_code}) from Preservation at #{resp_env_url}: #{resp_body}"
      expect(formatter.format).to eq(exp_msg)
    end

    context 'when an object id is not set' do
      subject(:formatter) { described_class.new(response: response, object_id: '', client_method_name: 'whatever') }

      it 'has sensible error message without object id' do
        exp_msg = "Preservation::Client.whatever got #{resp_status_msg} (#{resp_code}) from Preservation at #{resp_env_url}: #{resp_body}"
        expect(formatter.format).to eq(exp_msg)
      end
    end

    context 'when no reason_phrase' do
      let(:response) { instance_double(Faraday::Response, reason_phrase: nil, status: resp_code, body: resp_body, env: resp_env) }

      it 'has sensible error message without reason_phrase id' do
        exp_msg = "Preservation::Client.#{method_name} for #{druid} got #{resp_code} from Preservation at #{resp_env_url}: #{resp_body}"
        expect(formatter.format).to eq(exp_msg)
      end
    end
  end
end
