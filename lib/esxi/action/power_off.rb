require "i18n"

module VagrantPlugins
  module ESXi
    module Action
      class PowerOff

        def initialize(app, env)
          @app = app
        end

        def call(env)

          config = env[:machine].provider_config

          env[:ui].info "Power off VM"
          system("ssh #{config.user}@#{config.host} vim-cmd vmsvc/power.off '[#{config.datastore}]\\ #{config.name}/#{env[:machine].config.vm.box}.vmx' > /dev/null")

          @app.call env
        end
      end
    end
  end
end
