require 'net/http'
require 'uri'
require 'puppet/util/json'

class Puppet::Provider::InProd < Puppet::Provider
  initvars

  class Error < ::StandardError
  end

  def self.connect(username, password, hostname, ssl = false)
    uri = URI(hostname)
    res = Net::HTTP.post_form(uri,'username'=>username,'password'=>password)
    jsondata=Puppet::Util::Json.load(res.body)
    return jsondata
  end

  #/api/v1/change-set/change-set/2/validate
  #/api/v1/change-set/change-set/2/execute
  def self.ChangeSetAPI(apiLink, changeSetId, actions, token)
    fullUrlCreate = apiLink+changeSetId+'/'+actions+'/'
    uri = URI.parse(fullUrlCreate)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.request_uri)
    request["Authorization"] = "Token "+token
    response = http.request(request)
    response.each_header do |key, value|
      #  p "#{key} => #{value}"
    end
    return response.body
  end

  #/v1/change-set/change-set/execute_json/
  def self.ChangeSetExecuteJson(apiLink,token,filePath)
    jsond='';
    File.open(filePath).each do|line|
      jsond +=line
    end
    uri = URI.parse(apiLink)
    http = Net::HTTP.new(uri.host, uri.port)
    json_headers = {"Content-Type" => "application/json",
      "Accept" => "application/json","Authorization"=>"Token "+token}
    response = http.post(uri.path, jsond, json_headers)
    return response.body
    end
end
