module VagrantPlugins
  module ESXi
    module Util
      module MachineHelpers
        def wait_for_ssh(env)
          env[:ui].info(I18n.t("esxi.waiting_for_ssh"))
          while true                        
            break if env[:machine].communicate.ready?
            sleep 5
          end  
        end
      end
    end
  end
end
