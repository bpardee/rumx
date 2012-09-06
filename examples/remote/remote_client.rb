require 'json'
require 'net/http'

class RemoteClient

  def initialize(root_bean, host, port, timeout)
    @root_bean, @host, @port, @timeout = root_bean, host, port, timeout
  end

  def load_from_server
    @bean_name = "#{@host.gsub('.', '_')}_#{@port}"
    serialize_path = Rumx::Server.serialize_path([], 'json')
    hash = JSON.parse(remote_call(serialize_path))
    @root_bean.bean_add_child(@bean_name, Rumx::RemoteBean.new(hash, self))
  rescue Exception => e
    puts "#{e.message}\n\t#{e.backtrace.join("\n\t")}"
    @root_bean.bean_add_child(@bean_name, Rumx::Beans::Message.new(e.message))
  end

  def run_operation(ancestry, operation, argument_hash)
    operation_path = Rumx::Server.operation_path(ancestry, operation.name, 'json')
    return operation.type.string_to_value(remote_call(operation_path, argument_hash))
  end

  def set_attributes(ancestry, params)
    attributes_path = Rumx::Server.attributes_path(ancestry, 'json')
    return JSON.parse(remote_call(attributes_path, params))
  end

  #######
  private
  #######

  # Make a remote call yielding a pair of json, error_message where only 1 has a value.  If post_params is non-nil,
  # the request will be a POST otherwise it will be a GET.
  def remote_call(path, post_params=nil, &block)
    if post_params
      req = Net::HTTP::Post.new(path)
      req.set_form_data(post_params)
    else
      req = Net::HTTP::Get.new(path)
    end
    res = Net::HTTP.start(@host, @port) do |http|
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      http.request(req)
    end
    puts "Returned (#{res.code}) #{res.message} #{res.body}"
    case res
      when Net::HTTPSuccess
        return res.body
      else
        raise "Communication failure: (#{res.code}) #{res.message}"
    end
  rescue Exception => e
    puts "#{@host}:#{@port} - #{e.message}"
    raise
  end
end
