require "vagrant"

module VagrantPlugins
  module ESXi
    module Errors
      class VagrantESXiError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_esxi.errors")
      end

      class OvfError < VagrantESXiError
        error_key(:ovf_error)
      end

      class RsyncError < VagrantESXiError
        error_key(:rsync_error)
      end

      class VmRegisteringError < VagrantESXiError
        error_key(:vm_registering_error)
      end

      class VmImageExistsError < VagrantESXiError
        error_key(:vm_image_exists)
      end

      class VMNicCreateError < VagrantESXiError
        error_key(:nic_error)
      end
      class VMHdCreateError < VagrantESXiError
        error_key(:add_drive_error)
      end
      class VMHdExpandError < VagrantESXiError
        error_key(:expand_drive_error)
      end
    end
  end
end


