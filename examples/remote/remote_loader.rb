class RemoteLoader
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['REQUEST_PATH'] == '/remote'
      host_ports = ENV['RUMX_SERVERS'].split
      # Requery all the servers whenever the root node is displayed
      Rumx::Bean.add_root('remote', RemoteRoot.new(host_ports))
    end
    @app.call(env)
  end
end
