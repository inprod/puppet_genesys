require 'spec_helper'
require 'puppet/type/changeset'

describe Puppet::Type.type(:changeset) do
  let(:valid_params) do
    {
      name: 'execute',
      action: 'execute',
      changesetid: '124',
      apihost: 'https://test.example.com',
      apikey: 'a1b2c3d4e5f6a7b8',
      ensure: :present,
    }
  end

  describe 'when validating attributes' do
    it 'should have :action as its namevar' do
      expect(described_class.key_attributes).to eq([:action])
    end

    [:apihost, :apikey, :action, :path, :changesetid, :environment, :timeout, :poll_interval].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    it 'should have an ensure property' do
      expect(described_class.attrtype(:ensure)).to eq(:property)
    end
  end

  describe 'when validating action' do
    ['execute', 'validate', 'executejson'].each do |action|
      it "should accept '#{action}' as a valid action" do
        expect {
          described_class.new(valid_params.merge(name: action, action: action))
        }.not_to raise_error
      end
    end

    it 'should reject an invalid action' do
      expect {
        described_class.new(valid_params.merge(name: 'invalid', action: 'invalid'))
      }.to raise_error(Puppet::Error, /Action must be one of these values/)
    end

    it 'should reject an empty action' do
      expect {
        described_class.new(valid_params.merge(name: '', action: ''))
      }.to raise_error(Puppet::Error, /Action must be one of these values/)
    end
  end

  describe 'when validating apihost' do
    it 'should accept a valid HTTPS URL' do
      expect {
        described_class.new(valid_params.merge(apihost: 'https://your-company.inprod.io'))
      }.not_to raise_error
    end

    it 'should accept a valid HTTP URL' do
      expect {
        described_class.new(valid_params.merge(apihost: 'http://inprod.example.com'))
      }.not_to raise_error
    end

    it 'should reject an empty apihost' do
      expect {
        described_class.new(valid_params.merge(apihost: ''))
      }.to raise_error(Puppet::Error, /is not a valid URL/)
    end
  end

  describe 'when validating apikey' do
    it 'should accept a valid API key' do
      expect {
        described_class.new(valid_params.merge(apikey: 'a1b2c3d4e5f6a7b8'))
      }.not_to raise_error
    end

    it 'should reject an empty API key' do
      expect {
        described_class.new(valid_params.merge(apikey: ''))
      }.to raise_error(Puppet::Error, /InProd API Key is required/)
    end

    it 'should be marked as sensitive' do
      resource = described_class.new(valid_params)
      expect(described_class.attrclass(:apikey).new(resource: resource)).to respond_to(:sensitive)
    end
  end

  describe 'when validating changesetid' do
    it 'should accept a numeric changeset id' do
      expect {
        described_class.new(valid_params.merge(changesetid: '124'))
      }.not_to raise_error
    end

    it 'should reject a non-numeric changeset id' do
      expect {
        described_class.new(valid_params.merge(changesetid: 'abc'))
      }.to raise_error(Puppet::Error, /Only numeric values are allowed/)
    end

    it 'should reject a mixed alphanumeric changeset id' do
      expect {
        described_class.new(valid_params.merge(changesetid: '12abc'))
      }.to raise_error(Puppet::Error, /Only numeric values are allowed/)
    end
  end

  describe 'when validating environment' do
    it 'should accept an environment name' do
      expect {
        described_class.new(valid_params.merge(environment: 'Production'))
      }.not_to raise_error
    end

    it 'should accept an environment ID' do
      expect {
        described_class.new(valid_params.merge(environment: '3'))
      }.not_to raise_error
    end

    it 'should be optional' do
      expect {
        described_class.new(valid_params)
      }.not_to raise_error
    end
  end

  describe 'when validating timeout' do
    it 'should default to 300' do
      resource = described_class.new(valid_params)
      expect(resource[:timeout]).to eq(300)
    end

    it 'should accept a custom timeout' do
      resource = described_class.new(valid_params.merge(timeout: 60))
      expect(resource[:timeout]).to eq(60)
    end

    it 'should reject zero' do
      expect {
        described_class.new(valid_params.merge(timeout: 0))
      }.to raise_error(Puppet::Error, /timeout must be a positive integer/)
    end

    it 'should reject negative values' do
      expect {
        described_class.new(valid_params.merge(timeout: -1))
      }.to raise_error(Puppet::Error, /timeout must be a positive integer/)
    end
  end

  describe 'when validating poll_interval' do
    it 'should default to 5' do
      resource = described_class.new(valid_params)
      expect(resource[:poll_interval]).to eq(5)
    end

    it 'should accept a custom poll_interval' do
      resource = described_class.new(valid_params.merge(poll_interval: 10))
      expect(resource[:poll_interval]).to eq(10)
    end

    it 'should reject zero' do
      expect {
        described_class.new(valid_params.merge(poll_interval: 0))
      }.to raise_error(Puppet::Error, /poll_interval must be a positive integer/)
    end
  end
end
