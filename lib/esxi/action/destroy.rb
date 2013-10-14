module VagrantPlugins
  module ESXi
    module Action
      class Destroy

        def initialize(app, env)
          @app = app
        end

        def call(env)
          destroy_vm env
          env[:machine].id = nil

          @app.call env
        end

        private 
        
        def destroy_vm(env)

          config = env[:machine].provider_config

          env[:ui].info I18n.t("vagrant_esxi.unregistering")
          system("ssh #{config.user}@#{config.host} vim-cmd vmsvc/unregister '[#{config.datastore}]\\ #{config.name}/#{env[:machine].config.vm.box}.vmx'")

          env[:ui].info I18n.t("vagrant_esxi.removing")
          system("ssh #{config.user}@#{config.host} rm -rf /vmfs/volumes/#{config.datastore}/#{config.name}")

        end
      end
    end
  end
end
