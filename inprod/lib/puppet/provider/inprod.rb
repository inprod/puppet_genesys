require 'net/http'
require 'uri'
require 'json'

class Puppet::Provider::InProd < Puppet::Provider
  initvars

  TERMINAL_STATUSES = %w[SUCCESS FAILURE REVOKED].freeze

  # PUT /api/v1/change-set/change-set/{id}/{action}/
  def self.changeset_api(api_host, changeset_id, action, api_key)
    host = api_host.chomp('/')
    url = "#{host}/api/v1/change-set/change-set/#{changeset_id}/#{action}/"
    uri = URI.parse(url)
    http = build_http(uri)
    request = Net::HTTP::Put.new(uri.request_uri)
    request['Authorization'] = "Api-Key #{api_key}"
    response = http.request(request)
    check_response!(response)
    JSON.parse(response.body)
  end

  # POST /api/v1/change-set/change-set/execute_json/
  def self.changeset_execute_json(api_host, api_key, file_path, environment = nil)
    post_file(api_host, api_key, 'execute_json', file_path, 'application/json', environment)
  end

  # POST /api/v1/change-set/change-set/execute_yaml/
  def self.changeset_execute_yaml(api_host, api_key, file_path, environment = nil)
    post_file(api_host, api_key, 'execute_yaml', file_path, 'application/x-yaml', environment)
  end

  # POST /api/v1/change-set/change-set/validate_json/
  def self.changeset_validate_json(api_host, api_key, file_path, environment = nil)
    post_file(api_host, api_key, 'validate_json', file_path, 'application/json', environment)
  end

  # POST /api/v1/change-set/change-set/validate_yaml/
  def self.changeset_validate_yaml(api_host, api_key, file_path, environment = nil)
    post_file(api_host, api_key, 'validate_yaml', file_path, 'application/x-yaml', environment)
  end

  # GET /api/v1/task-status/{task_id}/
  def self.poll_task_status(api_host, api_key, task_id, timeout, poll_interval)
    host = api_host.chomp('/')
    url = "#{host}/api/v1/task-status/#{task_id}/"
    uri = URI.parse(url)
    elapsed = 0

    loop do
      http = build_http(uri)
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = "Api-Key #{api_key}"
      response = http.request(request)
      check_response!(response)

      data = JSON.parse(response.body)
      status = data['status']

      Puppet.debug("Task #{task_id} status: #{status} (#{elapsed}s elapsed)")

      case status
      when 'SUCCESS'
        return data['result']
      when 'FAILURE'
        raise(Puppet::Error, "Task failed: #{data['error']}")
      when 'REVOKED'
        raise(Puppet::Error, "Task #{task_id} was cancelled")
      end

      if elapsed >= timeout
        raise(Puppet::Error, "Timed out after #{timeout}s waiting for task #{task_id} (last status: #{status})")
      end

      sleep(poll_interval)
      elapsed += poll_interval
    end
  end

  def self.post_file(api_host, api_key, endpoint, file_path, content_type, environment = nil)
    host = api_host.chomp('/')
    file_data = File.read(file_path)
    url = "#{host}/api/v1/change-set/change-set/#{endpoint}/"
    url += "?environment=#{URI.encode_www_form_component(environment)}" if environment
    uri = URI.parse(url)
    http = build_http(uri)
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Authorization'] = "Api-Key #{api_key}"
    request['Content-Type'] = content_type
    request['Accept'] = 'application/json'
    request.body = file_data
    response = http.request(request)
    check_response!(response)
    JSON.parse(response.body)
  end
  private_class_method :post_file

  def self.build_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
    http
  end
  private_class_method :build_http

  def self.check_response!(response)
    return if response.is_a?(Net::HTTPSuccess)

    Puppet.debug("HTTP #{response.code}: #{response.body}")
    raise(Puppet::Error, "InProd API returned HTTP #{response.code}: #{response.message}")
  end
  private_class_method :check_response!
end
