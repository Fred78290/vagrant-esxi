module VagrantPlugins
  module ESXi
    module Action
      class IsCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)

          config = env[:machine].provider_config

          env[:result] = system("ssh #{config.user}@#{config.host} vim-cmd vmsvc/getallvms | grep '\\[#{config.datastore}\\] #{config.name}/#{config.name}.vmx' > /dev/null")

          @app.call env
        end
      end
    end
  end
end
