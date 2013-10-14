module VagrantPlugins
  module ESXi
    module Action
      class PowerOn

        def initialize(app, env)
          @app = app
        end

        def call(env)

          config = env[:machine].provider_config

          env[:ui].info I18n.t("vagrant_esxi.powering_on")
          system("ssh #{config.user}@#{config.host} vim-cmd vmsvc/power.on '[#{config.datastore}]\\ #{config.name}/#{env[:machine].config.vm.box}.vmx' > /dev/null")

          # wait for SSH to be available 
          env[:ui].info(I18n.t("vagrant_esxi.waiting_for_ssh"))
          while true
            break if env[:interrupted]                       
            break if env[:machine].communicate.ready?
            sleep 5
          end  
          
          @app.call env
        end
      end
    end
  end
end
