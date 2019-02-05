module VagrantPlugins
  module ESXi
    module Action
      class PowerOff

        def initialize(app, env)
          @app = app
        end

        def call(env)

          config = env[:machine].provider_config

          env[:ui].info I18n.t("vagrant_esxi.powering_off")
          system("ssh #{config.user}@#{config.host} vim-cmd vmsvc/power.off '[#{config.datastore}]\\ #{config.name}/#{config.name}.vmx' > /dev/null")

          @app.call env
        end
      end
    end
  end
end
