Puppet::Type.newtype(:changeset) do
  @doc = 'Running InProd Changesets'
  ensurable

  newparam(:apihost) do
    desc 'InProd API Host address (e.g. https://your-company.inprod.io)'
    validate do |value|
      if value.empty?
        raise ArgumentError, "#{value} is not a valid URL."
      end
    end
  end

  newparam(:apikey) do
    desc 'InProd API Key for authentication.'
    sensitive true
    validate do |value|
      if value.empty?
        raise ArgumentError, 'InProd API Key is required.'
      end
    end
  end

  newparam(:action) do
    isnamevar
    desc 'Action To Perform'
    valid_methods = ['execute', 'validate', 'executejson', 'executeyaml', 'validatejson', 'validateyaml']
    error_message = "Action must be one of these values: #{valid_methods}"
    validate do |value|
      raise ArgumentError, error_message if !value || value.empty?
      value.split(',').each do |operation|
        raise ArgumentError, error_message unless valid_methods.include?(operation)
      end
    end
  end

  newparam(:path) do
    desc 'File path to JSON or YAML payload for file-based actions'
  end

  newparam(:changesetid) do
    desc 'Changeset Id value'
    validate do |value|
      unless value =~ /\A[0-9]+\z/
        raise ArgumentError, "#{value} is not a valid Change set Id. Only numeric values are allowed."
      end
    end
  end

  newparam(:environment) do
    desc 'Target environment ID or name. Overrides the environment in the JSON payload.'
  end

  newparam(:timeout) do
    desc 'Maximum seconds to wait for task completion when polling. Default: 300'
    defaultto 300
    validate do |value|
      unless value.to_i.positive?
        raise ArgumentError, "timeout must be a positive integer, got #{value}"
      end
    end
    munge do |value|
      value.to_i
    end
  end

  newparam(:poll_interval) do
    desc 'Seconds between polling requests for task status. Default: 5'
    defaultto 5
    validate do |value|
      unless value.to_i.positive?
        raise ArgumentError, "poll_interval must be a positive integer, got #{value}"
      end
    end
    munge do |value|
      value.to_i
    end
  end
end
