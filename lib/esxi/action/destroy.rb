module VagrantPlugins
  module ESXi
    module Action
      class Destroy

        def initialize(app, _env)
          @app = app
        end

        def call(env)
          destroy_vm env
          env[:machine].id = nil

          @app.call env
        end

        private 
        
        def destroy_vm_by_name(env, config, name)
          _msg = I18n.t("vagrant_esxi.unregistering")
          env[:ui].info "#{_msg} --> #{name}"
          system("ssh #{config.user}@#{config.host} vim-cmd vmsvc/unregister '[#{config.datastore}]\\ #{name}/#{name}.vmx'")

          _msg = I18n.t("vagrant_esxi.removing")
          env[:ui].info "#{_msg} --> #{name}"
          system("ssh #{config.user}@#{config.host} rm -rf /vmfs/volumes/#{config.datastore}/#{name}")
        end

        def destroy_vm(env)
          config = env[:machine].provider_config

          destroy_vm_by_name(env, config, config.name)

          if config.create_template && config.destroy_template && config.template_name.nil? == false && config.is_vm_exists(config.template_name) then
            destroy_vm_by_name(env, config, config.template_name)
          end
        end
      end
    end
  end
end
