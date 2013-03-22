class RemoteRoot
  include Rumx::Bean

  class MyThread < Thread
    attr_reader :bean_name, :bean

    def initialize(host_port)
      @host, @port = host_port.split(':')
      super do
        @bean_name = "#{@host.gsub('.', '_')}_#{@port}".to_sym
        client = RemoteClient.new(self, @host, @port, 10)
        @bean = client.load_from_server
      end
    end
  end

  # Initialize with an array of strings of the form <host>:<port>
  def initialize(hosts_ports)
    @hosts_ports = hosts_ports
  end

  # Called whenever Bean.root(:remote) is performed
  def bean_root_hook
    # Load em up concurrently
    threads = @hosts_ports.map { |host_port| MyThread.new(host_port) }
    new_bean_children = {}
    threads.each do |t|
      t.join
      new_bean_children[t.bean_name] = t.bean
    end
    bean_reset_children(new_bean_children)
  end
end
