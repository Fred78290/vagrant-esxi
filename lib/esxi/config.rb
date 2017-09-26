require "vagrant"

module VagrantPlugins
  module ESXi
    class Config < Vagrant.plugin("2", :config)
      def initialize
        @vmx = {}
        @nic_inversed = true
        @network_adapters = {}
        # We require that network adapter 1 is a NAT device.
        #network_adapter(1, :private_network)
      end
      
      attr_accessor :host
      attr_accessor :user
      attr_accessor :password
      attr_accessor :name
      attr_accessor :datastore
      attr_accessor :add_hd
      attr_accessor :memory_mb
      attr_accessor :cpu_count
      attr_accessor :vmx
      attr_accessor :network
      attr_accessor :nic_inversed
      
      # The defined network adapters.
      #
      # @return [Hash]
      attr_reader :network_adapters

      # This defines a network adapter that will be added to the VirtualBox
      # virtual machine in the given slot.
      #
      # @param [Integer] slot The slot for this network adapter.
      # @param [Symbol] type The type of adapter.
      def network_adapter(slot, type, **opts)
        @network_adapters[slot] = [type, opts]
      end

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t("config.host") if host.nil?
        errors << I18n.t("config.user") if user.nil?
        errors << I18n.t("config.name") if name.nil?
        errors << I18n.t("config.datastore") if datastore.nil?
        errors << I18n.t("config.network") if network.nil?
        
        { "esxi Provider" => errors }
      end
    end
  end
end
