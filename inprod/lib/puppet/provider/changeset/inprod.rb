require File.expand_path(File.join(File.dirname(__FILE__), '..', 'inprod'))
require 'json'

Puppet::Type.type(:changeset).provide(:inprod, parent: Puppet::Provider::InProd) do
  desc 'InProd Api'

  def create
    action = resource[:action]
    api_host = resource[:apihost]
    api_key = resource[:apikey]
    timeout = resource[:timeout]
    poll_interval = resource[:poll_interval]

    case action
    when 'execute'
      execute_changeset(api_host, api_key, resource[:changesetid], timeout, poll_interval)

    when 'validate'
      validate_changeset(api_host, api_key, resource[:changesetid], timeout, poll_interval)

    when 'executejson'
      execute_file_changeset(api_host, api_key, resource[:path], resource[:environment], timeout, poll_interval,
                             :changeset_execute_json)

    when 'executeyaml'
      execute_file_changeset(api_host, api_key, resource[:path], resource[:environment], timeout, poll_interval,
                             :changeset_execute_yaml)

    when 'validatejson'
      validate_file_changeset(api_host, api_key, resource[:path], resource[:environment], timeout, poll_interval,
                              :changeset_validate_json)

    when 'validateyaml'
      validate_file_changeset(api_host, api_key, resource[:path], resource[:environment], timeout, poll_interval,
                              :changeset_validate_yaml)

    else
      raise(Puppet::Error, "Invalid changeset action: #{action}")
    end
  end

  def destroy
    Puppet.debug('changeset destroy called')
    raise(Puppet::Error, 'Not implemented')
  end

  def exists?
    false
  end

  private

  def execute_changeset(api_host, api_key, changeset_id, timeout, poll_interval)
    response = self.class.changeset_api(api_host, changeset_id, 'execute', api_key)
    task_id = extract_task_id(response)

    Puppet.info("Execute task started: #{task_id}")
    result = self.class.poll_task_status(api_host, api_key, task_id, timeout, poll_interval)

    unless result['successful']
      raise(Puppet::Error, "Change set execution failed: #{result.to_json}")
    end

    Puppet.info("Change set executed successfully (run_id: #{result['run_id']})")
  end

  def validate_changeset(api_host, api_key, changeset_id, timeout, poll_interval)
    response = self.class.changeset_api(api_host, changeset_id, 'validate', api_key)
    task_id = extract_task_id(response)

    Puppet.info("Validate task started: #{task_id}")
    result = self.class.poll_task_status(api_host, api_key, task_id, timeout, poll_interval)

    unless result['is_valid']
      errors = format_validation_errors(result['validation_results'])
      raise(Puppet::Error, "Change set validation failed:\n#{errors}")
    end

    Puppet.info('Change set validated successfully')
  end

  def execute_file_changeset(api_host, api_key, file_path, environment, timeout, poll_interval, api_method)
    response = self.class.send(api_method, api_host, api_key, file_path, environment)
    task_id = extract_task_id(response)

    Puppet.info("Execute file task started: #{task_id}")
    result = self.class.poll_task_status(api_host, api_key, task_id, timeout, poll_interval)

    unless result['successful']
      raise(Puppet::Error, "Change set execution failed: #{result.to_json}")
    end

    Puppet.info("Change set executed successfully (run_id: #{result['run_id']})")
  end

  def validate_file_changeset(api_host, api_key, file_path, environment, timeout, poll_interval, api_method)
    response = self.class.send(api_method, api_host, api_key, file_path, environment)
    task_id = extract_task_id(response)

    Puppet.info("Validate file task started: #{task_id}")
    result = self.class.poll_task_status(api_host, api_key, task_id, timeout, poll_interval)

    unless result['is_valid']
      errors = format_validation_errors(result['validation_results'])
      raise(Puppet::Error, "Change set validation failed:\n#{errors}")
    end

    Puppet.info('Change set validated successfully')
  end

  def extract_task_id(response)
    task_id = response.dig('data', 'attributes', 'task_id')
    raise(Puppet::Error, "No task_id in API response: #{response.to_json}") unless task_id
    task_id
  end

  def format_validation_errors(validation_results)
    return 'No details available' unless validation_results.is_a?(Array)

    messages = []
    validation_results.each do |action_result|
      action_id = action_result['action_id']
      next unless action_result['errors'].is_a?(Hash)

      action_result['errors'].each do |field, field_errors|
        next unless field_errors.is_a?(Array)

        field_errors.each do |entry|
          next unless entry.is_a?(Hash) && entry['msg'].is_a?(Array)

          entry['msg'].each do |msg|
            messages << "Action #{action_id} - #{field}: #{msg}"
          end
        end
      end
    end

    messages.empty? ? 'Validation failed with unknown errors' : messages.join("\n")
  end
end
