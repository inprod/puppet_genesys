Puppet::Type.newtype(:changeset) do
  @doc = "Running InProd Changesets"
  ensurable

  newparam(:apihost) do
    desc "InProd API Host address"
    validate do |value|
      if value.empty?
        raise ArgumentError , "%s is not a valid URL."
      end
    end
  end

 newparam(:apiusername) do
    desc "InProd API Username"
    validate do |value|
      if value.empty?
        raise ArgumentError , "API Username is required."
      end
    end
  end

 newparam(:apipassword) do
    desc "InProd API Password."
    validate do |value|
      if value.empty?
          raise ArgumentError , "InProd API Password is required."
      end
    end
  end

  newparam(:action) do
    isnamevar
    desc "Action To Perform"
    valid_methods = ['execute', 'validate','executejson']
    error_message = "Action must one of these values: #{valid_methods}"
    validate do |value|
      raise ArgumentError, error_message if !value or value.empty?
      value.split(',').each do |operation|
      raise ArgumentError, error_message unless valid_methods.include? operation
      end
    end
  end

  newparam(:path) do
    desc "File path to use"
    # TODO validate that the file exists on the agent
    # https://puppet.com/docs/puppet/5.5/custom_types.html#agent-side-pre-run-resource-validation-puppet-37-and-later
  end

  newparam(:changesetid) do
    desc "Changeset Id value"
    validate do |value|
      unless value =~ /[0-9]/
        raise ArgumentError , "Enter Number is not a valid Change set Id Only Numeric Value Allowed"
      end
    end
  end
end
