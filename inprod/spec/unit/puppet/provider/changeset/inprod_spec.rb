require 'spec_helper'
require 'puppet/type/changeset'
require 'puppet/provider/inprod'
require 'puppet/provider/changeset/inprod'

describe Puppet::Type.type(:changeset).provider(:inprod) do
  let(:resource_params) do
    {
      name: 'execute',
      action: 'execute',
      changesetid: '124',
      apihost: 'https://test.example.com',
      apikey: 'a1b2c3d4e5f6a7b8',
      timeout: 300,
      poll_interval: 5,
      ensure: :present,
    }
  end

  let(:resource) { Puppet::Type.type(:changeset).new(resource_params) }
  let(:provider) { described_class.new(resource) }

  let(:task_id) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  # API initial responses (async — return task_id)
  let(:execute_initial_response) do
    {
      'data' => {
        'type' => 'change-set-confirmation',
        'attributes' => {
          'title' => 'Processing...',
          'description' => 'Your change set is being run in the background.',
          'run_id' => 24,
          'successful' => nil,
          'task_id' => task_id,
        },
      },
    }
  end

  let(:validate_initial_response) do
    {
      'data' => {
        'type' => 'change-set-validation',
        'attributes' => {
          'title' => 'Validation in progress',
          'description' => 'Changeset validation is running as a background task.',
          'task_id' => task_id,
        },
      },
    }
  end

  # Polling results
  let(:execute_success_result) do
    {
      'run_id' => 24,
      'successful' => true,
      'changeset_name' => 'Deploy Queue Config',
      'environment' => { 'id' => 3, 'name' => 'Production' },
    }
  end

  let(:execute_failure_result) do
    {
      'run_id' => 24,
      'successful' => false,
      'changeset_name' => 'Deploy Queue Config',
      'environment' => { 'id' => 3, 'name' => 'Production' },
    }
  end

  let(:validate_success_result) do
    {
      'is_valid' => true,
      'validation_results' => [],
      'changeset_name' => 'Deploy Queue Config',
      'environment' => { 'id' => 3, 'name' => 'Production' },
    }
  end

  let(:validate_failure_result) do
    {
      'is_valid' => false,
      'validation_results' => [
        {
          'action_id' => 534,
          'errors' => {
            'folderDbid' => [{ 'iteration' => nil, 'msg' => ['No object found with query'] }],
          },
          'warnings' => {},
        },
      ],
      'changeset_name' => 'Deploy Queue Config',
      'environment' => { 'id' => 3, 'name' => 'Production' },
    }
  end

  describe '#exists?' do
    it 'always returns false' do
      expect(provider.exists?).to eq(false)
    end
  end

  describe '#create' do
    context 'with execute action' do
      it 'succeeds when task completes successfully' do
        allow(described_class).to receive(:changeset_api).and_return(execute_initial_response)
        allow(described_class).to receive(:poll_task_status).and_return(execute_success_result)
        expect { provider.create }.not_to raise_error
      end

      it 'raises an error when execution fails' do
        allow(described_class).to receive(:changeset_api).and_return(execute_initial_response)
        allow(described_class).to receive(:poll_task_status).and_return(execute_failure_result)
        expect { provider.create }.to raise_error(Puppet::Error, /Change set execution failed/)
      end

      it 'raises an error when polling reports task failure' do
        allow(described_class).to receive(:changeset_api).and_return(execute_initial_response)
        allow(described_class).to receive(:poll_task_status).and_raise(Puppet::Error, 'Task failed: Connection timeout')
        expect { provider.create }.to raise_error(Puppet::Error, /Task failed: Connection timeout/)
      end

      it 'raises an error when no task_id in response' do
        bad_response = { 'data' => { 'attributes' => {} } }
        allow(described_class).to receive(:changeset_api).and_return(bad_response)
        expect { provider.create }.to raise_error(Puppet::Error, /No task_id in API response/)
      end
    end

    context 'with validate action' do
      let(:resource_params) do
        {
          name: 'validate',
          action: 'validate',
          changesetid: '125',
          apihost: 'https://test.example.com',
          apikey: 'a1b2c3d4e5f6a7b8',
          timeout: 300,
          poll_interval: 5,
          ensure: :present,
        }
      end

      it 'succeeds when validation passes' do
        allow(described_class).to receive(:changeset_api).and_return(validate_initial_response)
        allow(described_class).to receive(:poll_task_status).and_return(validate_success_result)
        expect { provider.create }.not_to raise_error
      end

      it 'raises an error when validation finds errors' do
        allow(described_class).to receive(:changeset_api).and_return(validate_initial_response)
        allow(described_class).to receive(:poll_task_status).and_return(validate_failure_result)
        expect { provider.create }.to raise_error(Puppet::Error, /Change set validation failed/)
      end

      it 'includes error details in the failure message' do
        allow(described_class).to receive(:changeset_api).and_return(validate_initial_response)
        allow(described_class).to receive(:poll_task_status).and_return(validate_failure_result)
        expect { provider.create }.to raise_error(Puppet::Error, /No object found with query/)
      end

      it 'includes action ID in the failure message' do
        allow(described_class).to receive(:changeset_api).and_return(validate_initial_response)
        allow(described_class).to receive(:poll_task_status).and_return(validate_failure_result)
        expect { provider.create }.to raise_error(Puppet::Error, /Action 534/)
      end
    end

    context 'with executejson action' do
      let(:resource_params) do
        {
          name: 'executejson',
          action: 'executejson',
          path: '/path/to/changeset.json',
          apihost: 'https://test.example.com',
          apikey: 'a1b2c3d4e5f6a7b8',
          environment: 'Production',
          timeout: 300,
          poll_interval: 5,
          ensure: :present,
        }
      end

      it 'succeeds when task completes successfully' do
        allow(described_class).to receive(:changeset_execute_json).and_return(execute_initial_response)
        allow(described_class).to receive(:poll_task_status).and_return(execute_success_result)
        expect { provider.create }.not_to raise_error
      end

      it 'passes environment parameter to API' do
        allow(described_class).to receive(:poll_task_status).and_return(execute_success_result)
        expect(described_class).to receive(:changeset_execute_json).with(
          'https://test.example.com',
          'a1b2c3d4e5f6a7b8',
          '/path/to/changeset.json',
          'Production'
        ).and_return(execute_initial_response)
        provider.create
      end

      it 'raises an error when execution fails' do
        allow(described_class).to receive(:changeset_execute_json).and_return(execute_initial_response)
        allow(described_class).to receive(:poll_task_status).and_return(execute_failure_result)
        expect { provider.create }.to raise_error(Puppet::Error, /Change set execution failed/)
      end
    end
  end

  describe '#destroy' do
    it 'raises a not implemented error' do
      expect { provider.destroy }.to raise_error(Puppet::Error, /Not implemented/)
    end
  end
end

describe Puppet::Provider::InProd do
  let(:mock_http) { instance_double(Net::HTTP) }
  let(:mock_response) { instance_double(Net::HTTPSuccess) }

  before do
    allow(Net::HTTP).to receive(:new).and_return(mock_http)
    allow(mock_http).to receive(:use_ssl=)
    allow(mock_http).to receive(:verify_mode=)
  end

  describe '.changeset_api' do
    it 'sends a PUT request with Api-Key header' do
      allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(mock_response).to receive(:body).and_return('{"data":{"attributes":{"task_id":"test-uuid"}}}')
      allow(mock_http).to receive(:request) do |request|
        expect(request).to be_a(Net::HTTP::Put)
        expect(request['Authorization']).to eq('Api-Key testkey123')
        mock_response
      end

      result = described_class.changeset_api(
        'https://test.example.com',
        '124',
        'execute',
        'testkey123'
      )
      expect(result['data']['attributes']['task_id']).to eq('test-uuid')
    end

    it 'enables SSL for HTTPS URLs' do
      allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(mock_response).to receive(:body).and_return('{"data":{}}')
      allow(mock_http).to receive(:request).and_return(mock_response)

      expect(mock_http).to receive(:use_ssl=).with(true)
      expect(mock_http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)

      described_class.changeset_api('https://test.example.com', '124', 'execute', 'testkey123')
    end

    it 'raises an error on HTTP failure' do
      failed_response = instance_double(Net::HTTPForbidden)
      allow(failed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(failed_response).to receive(:code).and_return('403')
      allow(failed_response).to receive(:message).and_return('Forbidden')
      allow(failed_response).to receive(:body).and_return('Access denied')
      allow(mock_http).to receive(:request).and_return(failed_response)

      expect {
        described_class.changeset_api('https://test.example.com', '124', 'execute', 'testkey123')
      }.to raise_error(Puppet::Error, /HTTP 403/)
    end
  end

  describe '.changeset_execute_json' do
    let(:json_content) { '{"actions":[{"type":"create","object_type":"queue","name":"Test Queue"}]}' }

    it 'reads the file and sends a POST request with Api-Key header' do
      allow(File).to receive(:read).with('/path/to/changeset.json').and_return(json_content)
      allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(mock_response).to receive(:body).and_return('{"data":{"attributes":{"task_id":"test-uuid"}}}')
      allow(mock_http).to receive(:request) do |request|
        expect(request).to be_a(Net::HTTP::Post)
        expect(request['Authorization']).to eq('Api-Key testkey123')
        expect(request['Content-Type']).to eq('application/json')
        expect(request.body).to eq(json_content)
        mock_response
      end

      result = described_class.changeset_execute_json(
        'https://test.example.com',
        'testkey123',
        '/path/to/changeset.json'
      )
      expect(result['data']['attributes']['task_id']).to eq('test-uuid')
    end

    it 'appends environment query parameter when provided' do
      allow(File).to receive(:read).with('/path/to/changeset.json').and_return(json_content)
      allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(mock_response).to receive(:body).and_return('{"data":{"attributes":{"task_id":"test-uuid"}}}')
      allow(mock_http).to receive(:request) do |request|
        expect(request.path).to include('environment=Production')
        mock_response
      end

      described_class.changeset_execute_json(
        'https://test.example.com',
        'testkey123',
        '/path/to/changeset.json',
        'Production'
      )
    end

    it 'does not append environment query parameter when nil' do
      allow(File).to receive(:read).with('/path/to/changeset.json').and_return(json_content)
      allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(mock_response).to receive(:body).and_return('{"data":{"attributes":{"task_id":"test-uuid"}}}')
      allow(mock_http).to receive(:request) do |request|
        expect(request.path).not_to include('environment')
        mock_response
      end

      described_class.changeset_execute_json(
        'https://test.example.com',
        'testkey123',
        '/path/to/changeset.json',
        nil
      )
    end

    it 'raises an error when file does not exist' do
      allow(File).to receive(:read).with('/nonexistent/file.json').and_raise(Errno::ENOENT.new('No such file'))

      expect {
        described_class.changeset_execute_json(
          'https://test.example.com',
          'testkey123',
          '/nonexistent/file.json'
        )
      }.to raise_error(Errno::ENOENT)
    end
  end

  describe '.poll_task_status' do
    let(:task_id) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

    before do
      allow(described_class).to receive(:sleep)
    end

    it 'returns result when task succeeds' do
      success_response = instance_double(Net::HTTPSuccess)
      allow(success_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(success_response).to receive(:body).and_return({
        'task_id' => task_id,
        'status' => 'SUCCESS',
        'result' => { 'run_id' => 24, 'successful' => true },
      }.to_json)
      allow(mock_http).to receive(:request).and_return(success_response)

      result = described_class.poll_task_status('https://test.example.com', 'testkey', task_id, 300, 5)
      expect(result['successful']).to eq(true)
      expect(result['run_id']).to eq(24)
    end

    it 'raises an error when task fails' do
      failure_response = instance_double(Net::HTTPSuccess)
      allow(failure_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(failure_response).to receive(:body).and_return({
        'task_id' => task_id,
        'status' => 'FAILURE',
        'error' => 'Connection timeout to Genesys API',
      }.to_json)
      allow(mock_http).to receive(:request).and_return(failure_response)

      expect {
        described_class.poll_task_status('https://test.example.com', 'testkey', task_id, 300, 5)
      }.to raise_error(Puppet::Error, /Task failed: Connection timeout to Genesys API/)
    end

    it 'raises an error when task is revoked' do
      revoked_response = instance_double(Net::HTTPSuccess)
      allow(revoked_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(revoked_response).to receive(:body).and_return({
        'task_id' => task_id,
        'status' => 'REVOKED',
      }.to_json)
      allow(mock_http).to receive(:request).and_return(revoked_response)

      expect {
        described_class.poll_task_status('https://test.example.com', 'testkey', task_id, 300, 5)
      }.to raise_error(Puppet::Error, /was cancelled/)
    end

    it 'polls until success after pending/started states' do
      pending_response = instance_double(Net::HTTPSuccess)
      allow(pending_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(pending_response).to receive(:body).and_return({
        'task_id' => task_id,
        'status' => 'PENDING',
      }.to_json)

      started_response = instance_double(Net::HTTPSuccess)
      allow(started_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(started_response).to receive(:body).and_return({
        'task_id' => task_id,
        'status' => 'STARTED',
      }.to_json)

      success_response = instance_double(Net::HTTPSuccess)
      allow(success_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(success_response).to receive(:body).and_return({
        'task_id' => task_id,
        'status' => 'SUCCESS',
        'result' => { 'is_valid' => true, 'validation_results' => [] },
      }.to_json)

      allow(mock_http).to receive(:request).and_return(pending_response, started_response, success_response)

      result = described_class.poll_task_status('https://test.example.com', 'testkey', task_id, 300, 5)
      expect(result['is_valid']).to eq(true)
    end

    it 'raises timeout error when exceeded' do
      pending_response = instance_double(Net::HTTPSuccess)
      allow(pending_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(pending_response).to receive(:body).and_return({
        'task_id' => task_id,
        'status' => 'PENDING',
      }.to_json)
      allow(mock_http).to receive(:request).and_return(pending_response)

      expect {
        described_class.poll_task_status('https://test.example.com', 'testkey', task_id, 10, 5)
      }.to raise_error(Puppet::Error, /Timed out after 10s/)
    end

    it 'sends Api-Key header on poll requests' do
      success_response = instance_double(Net::HTTPSuccess)
      allow(success_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(success_response).to receive(:body).and_return({
        'task_id' => task_id,
        'status' => 'SUCCESS',
        'result' => { 'successful' => true },
      }.to_json)
      allow(mock_http).to receive(:request) do |request|
        expect(request).to be_a(Net::HTTP::Get)
        expect(request['Authorization']).to eq('Api-Key testkey')
        success_response
      end

      described_class.poll_task_status('https://test.example.com', 'testkey', task_id, 300, 5)
    end
  end
end
