require "vagrant"

module VagrantPlugins
  module ESXi
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :host
      attr_accessor :user
      attr_accessor :password
      attr_accessor :name
      attr_accessor :datastore
      attr_accessor :add_hd
      attr_accessor :memory_mb
      attr_accessor :cpu_count
      attr_accessor :network
      attr_accessor :nic_inversed
      attr_accessor :expand_hd
      attr_accessor :create_template
      attr_accessor :template_name
      attr_accessor :clone_template
      attr_accessor :destroy_template
      attr_accessor :vmx

      # The defined network adapters.
      #
      # @return [Hash]
      attr_reader :network_adapters
 
      def initialize
        @vmx = {}
        @network_adapters = {}

        @add_hd = UNSET_VALUE
        @expand_hd = UNSET_VALUE
        @create_template = UNSET_VALUE
        @template_name = UNSET_VALUE
        @clone_template = UNSET_VALUE
        @destroy_template = UNSET_VALUE
        @nic_inversed = UNSET_VALUE
      end
      
      def merge(other)
        super.tap do |result|
          c = @vmx.merge(other.vmx)
          result.instance_variable_set(:@vmx, c)
        end
      end

      def finalize!
        @create_template = false if @create_template == UNSET_VALUE
        @clone_template = false if @clone_template == UNSET_VALUE
        @destroy_template = false if @destroy_template == UNSET_VALUE
        @nic_inversed = false if @nic_inversed == UNSET_VALUE
        @expand_hd = nil if @expand_hd == UNSET_VALUE
        @add_hd = nil if @add_hd == UNSET_VALUE
      end

      def use_template()
        _use_template = false

        if template_name.nil? == false && is_vm_exists(template_name) then
          _use_template = true
        end

        return _use_template
      end

      def is_vm_exists(vm_name)
        dst_dir = "/vmfs/volumes/#{datastore}/#{vm_name}/#{vm_name}.vmx"

        return system("ssh #{user}@#{host} test -f #{dst_dir}")
      end
  
      # This defines a network adapter that will be added to the VirtualBox
      # virtual machine in the given slot.
      #
      # @param [Integer] slot The slot for this network adapter.
      # @param [Symbol] type The type of adapter.
      def network_adapter(slot, type, **opts)
        @network_adapters[slot] = [type, opts]
      end

      def validate(_machine)
        errors = _detected_errors
        
        errors << I18n.t("vagrant_esxi.config.host") if @host.nil?
        errors << I18n.t("vagrant_esxi.config.user") if @user.nil?
        errors << I18n.t("vagrant_esxi.config.password") if @password.nil?
        errors << I18n.t("vagrant_esxi.config.name") if @name.nil?
        errors << I18n.t("vagrant_esxi.config.datastore") if @datastore.nil?
        errors << I18n.t("vagrant_esxi.config.network") if @network.nil?
        
        { "esxi Provider" => errors }
      end
    end
  end
end
