class RemoteRoot
  include Rumx::Bean

  # Initialize with an array of strings of the form <host>:<port>
  def initialize(hosts_ports)
    threads = []

    hosts_ports.each do |host_port|
      host, port = host_port.split(':')
      client = RemoteClient.new(self, host, port, 10)
      # Load em up concurrently
      threads << Thread.new(client) { |client| client.load_from_server }
      threads.each {|t| t.join}
    end
  end
end
