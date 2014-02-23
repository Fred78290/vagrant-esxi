require "open3"

module VagrantPlugins
  module ESXi
    module Action
      class GetState

        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:machine_state_id] = get_state(env[:esxi_connection], env[:machine])

          @app.call env
        end

        private

        def get_state(connection, machine)
          return :not_created  if machine.id.nil?

          config = machine.provider_config

          o, s = Open3.capture2("ssh #{config.user}@#{config.host} vim-cmd vmsvc/power.getstate '[#{config.datastore}]\\ #{config.name}/#{machine.config.vm.box}.vmx'")

          return :not_created if s.eql?(1)

          if o.match(/Powered on/)
            :running
          else
            :poweroff
          end
        end
      end
    end
  end
end
