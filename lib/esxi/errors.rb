require "vagrant"

module VagrantPlugins
  module ESXi
    module Errors
      class ESXiError < Vagrant::Errors::VagrantError
        error_namespace("esxi.errors")
      end
    end
  end
end
