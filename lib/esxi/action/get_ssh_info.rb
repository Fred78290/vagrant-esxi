require "open3"

module VagrantPlugins
  module ESXi
    module Action
      class GetSshInfo

        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:machine_ssh_info] = get_ssh_info(env[:esxi_connection], env[:machine])

          @app.call env
        end

        private

        def get_ssh_info(connection, machine)

          config = machine.provider_config

          o, s = Open3.capture2("ssh #{config.user}@#{config.host} vim-cmd vmsvc/get.guest '[#{config.datastore}]\\ #{config.name}/#{config.name}.vmx'")
          m = /^   ipAddress = "(.*?)"/m.match(o)
          return nil if m.nil?

          return {
              :host => m[1],
              :port => 22
          }
        end
      end
    end
  end
end
