require File.expand_path(File.join(File.dirname(__FILE__), '..', 'inprod'))
require 'puppet/util/json'

Puppet::Type.type(:changeset).provide(:inprod, :parent => Puppet::Provider::InProd) do
  desc "InProd Api"

  def create
    performActionVariable = resource[:action]
    changeSetVariable = resource[:changesetid]
    tokenGet = self.class.connect(resource[:apiusername],resource[:apipassword],resource[:apihost]+"/api/admin/obtain-auth-token/",false)

    # executejson
    if performActionVariable=="executejson"
      if tokenGet["tokens"]
        authorizeToken = tokenGet["tokens"]["auth"]
        filePath = resource[:path]
        apiresponse = self.class.ChangeSetExecuteJson(resource[:apihost]+"/api/v1/change-set/change-set/execute_json/",authorizeToken, filePath)
        if valid_json(apiresponse)
          jsondata=Puppet::Util::Json.load(apiresponse)
          if jsondata["data"]["attributes"]["successful"]==false
            raise(Puppet::Error, jsondata["data"]["attributes"]["description"][0]["errors"])
          end
        elsif
          raise(Puppet::Error, apiresponse)
        end
      else
       raise(Puppet::Error, tokenGet["errors"]["base"])
      end

    # execute
    elsif performActionVariable=="execute"
      if tokenGet["tokens"]
        authorizeToken = tokenGet["tokens"]["auth"]
        apiresponse = self.class.ChangeSetAPI(resource[:apihost]+"/api/v1/change-set/change-set/", changeSetVariable, performActionVariable, authorizeToken)
        if valid_json(apiresponse)
          jsondata=Puppet::Util::Json.load(apiresponse)
          if jsondata["data"]

          elsif jsondata["errors"]["base"]
              raise(Puppet::Error, jsondata["errors"]["base"])
          end
        elsif
          raise(Puppet::Error, apiresponse)
        end
      else
       raise(Puppet::Error, tokenGet["errors"]["base"])
      end

    # Validate
    elsif performActionVariable=="validate"
      if tokenGet["tokens"]
        authorizeToken = tokenGet["tokens"]["auth"]
        apiresponse = self.class.ChangeSetAPI(resource[:apihost]+"/api/v1/change-set/change-set/", changeSetVariable, performActionVariable, authorizeToken)
        if valid_json(apiresponse)
          jsondata=Puppet::Util::Json.load(apiresponse)
          if jsondata[0]["error"]
            raise(Puppet::Error, jsondata[0]["error"])
          end
        elsif
          raise(Puppet::Error, apiresponse)
        end
      else
        raise(Puppet::Error, tokenGet["errors"]["base"])
      end

    # Catch all
    else
      raise(Puppet::Error, "Invalid changeset action")
    end
  end

  def destroy
    puts "The destroy was called"
    raise(Puppet::Error, "Not implemented")
  end

  def exists?
    puts "The exists was called"
    tokenGet = self.class.connect(resource[:apiusername],resource[:apipassword],resource[:apihost]+"/api/admin/obtain-auth-token/",false)
    if tokenGet["tokens"]
      return false
    else
      #raise(Puppet::Error, tokenGet["errors"]["base"])
      return true
    end
  end

  # custom functions
  def valid_json(response)
    Puppet::Util::Json.load(response)
    return true
    rescue JSON::ParserError => e
    return false
  end

end
