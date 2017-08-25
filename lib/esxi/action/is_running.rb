module VagrantPlugins
  module ESXi
    module Action
      class IsRunning
        
        def initialize(app, env)
          @app = app
        end

        def call(env)

          config = env[:machine].provider_config

          env[:result] = system("ssh #{config.user}@#{config.host} vim-cmd vmsvc/power.getstate '[#{config.datastore}]\\ #{config.name}/#{config.name}.vmx' | grep 'Powered on' > /dev/null")

          @app.call env
        end
      end
    end
  end
end
