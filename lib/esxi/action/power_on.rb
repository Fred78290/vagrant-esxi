require "i18n"
require "esxi/util/machine_helpers"

module VagrantPlugins
  module ESXi
    module Action
      class PowerOn
        include Util::MachineHelpers

        def initialize(app, env)
          @app = app
        end

        def call(env)

          config = env[:machine].provider_config

          env[:ui].info "Power on VM"
          system("ssh #{config.user}@#{config.host} vim-cmd vmsvc/power.on '[#{config.datastore}]\\ #{config.name}/#{env[:machine].config.vm.box}.vmx' > /dev/null")

          # wait for SSH to be available 
          wait_for_ssh env
          
          @app.call env
        end
      end
    end
  end
end
