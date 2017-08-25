require "vagrant"

module VagrantPlugins
  module ESXi
    class Config < Vagrant.plugin("2", :config)
      def initialize
        @vmx = {}
      end
      
      attr_accessor :host
      attr_accessor :user
      attr_accessor :password
      attr_accessor :template_name
      attr_accessor :name
      attr_accessor :datastore
      attr_accessor :add_hd
      attr_accessor :memory_mb
      attr_accessor :cpu_count
      attr_accessor :vmx

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t("config.host") if host.nil?
        errors << I18n.t("config.user") if user.nil?
        errors << I18n.t("config.name") if name.nil?
        errors << I18n.t("config.template_name") if name.nil?
        errors << I18n.t("config.datastore") if datastore.nil?

        { "esxi Provider" => errors }
      end
    end
  end
end
