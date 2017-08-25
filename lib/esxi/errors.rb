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

      class VmImageExistsError < VagrantESXiError
        error_key(:vm_image_exists)
      end

    end
  end
end


