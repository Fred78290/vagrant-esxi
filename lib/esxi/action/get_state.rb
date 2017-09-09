
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

          result = Vagrant::Util::Subprocess.execute("ssh", "#{config.user}@#{config.host}", "vim-cmd vmsvc/power.getstate '[#{config.datastore}] #{config.name}/#{config.name}.vmx'")

          if result.exit_code != 0
            return :not_created
          end

          if result.stdout.match(/Powered on/)
            :running
          else
            :poweroff
          end
        end
      end
    end
  end
end
