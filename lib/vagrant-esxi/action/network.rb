require "ipaddr"
require "set"

require "log4r"

require "vagrant/util/network_ip"
require "vagrant/util/scoped_hash_override"

module VagrantPlugins
    module ESXi
        module Action
            # This middleware class sets up all networking for the VirtualBox
            # instance. This includes host only networks, bridged networking,
            # forwarded ports, etc.
            #
            # This handles all the `config.vm.network` configurations.
            class Network
                include Vagrant::Util::NetworkIP
                include Vagrant::Util::ScopedHashOverride

                def initialize(app, env)
                    @logger = Log4r::Logger.new("vagrant::plugins::esxi::network")
                    @app    = app
                    @env    = env
                end

                def call(env)
                    # TODO: Validate network configuration prior to anything below
                    @env = env
                                        
                    # Get the list of network adapters from the configuration
                    network_adapters_config = env[:machine].provider_config.network_adapters.dup

                    # Assign the adapter slot for each high-level network
                    available_slots = Set.new(1..36)
                    network_adapters_config.each do |slot, _data|
                        available_slots.delete(slot)
                    end

                    @logger.debug("Available slots for high-level adapters: #{available_slots.inspect}")
                    @logger.info("Determining network adapters required for high-level configuration...")
                    available_slots = available_slots.to_a.sort
                    env[:machine].config.vm.networks.each do |type, options|
                        # We only handle private and public networks
                        next if type != :private_network && type != :public_network
            
                        options = scoped_hash_override(options, :esxi)
            
                        # Figure out the slot that this adapter will go into
                        slot = options[:adapter]
                        if !slot
                            if available_slots.empty?
                                raise Vagrant::Errors::VirtualBoxNoRoomForHighLevelNetwork
                            end
            
                            slot = available_slots.shift
                        end
                        
                        # Configure it
                        data = nil
                        if type == :private_network
                            # private_network = hostonly
                            data = [:hostonly, options]
                        elsif type == :public_network
                            # public_network = bridged
                            data = [:bridged, options]
                        elsif type == :internal_network
                            data = [:intnet, options]
                        end
            
                        # Store it!
                        @logger.info(" -- Slot #{slot}: #{data[0]}")
                        network_adapters_config[slot] = data
                    end
        
                    @logger.info("Determining adapters and compiling network configuration...")
                    adapters = []
                    networks = []

                    network_adapters_config.each do |slot, data|
                        type    = data[0]
                        options = data[1]
            
                        @logger.info("Network slot #{slot}. Type: #{type}.")
            
                        # Get the normalized configuration for this type
                        config = send("#{type}_config", options)
                        config[:adapter] = slot
                        @logger.debug("Normalized configuration: #{config.inspect}")
            
                        # Get the VirtualBox adapter configuration
                        adapter = send("#{type}_adapter", config)
                        adapters << adapter

                        @logger.debug("Adapter configuration: #{adapter.inspect}")
            
                        # Get the network configuration
                        network = send("#{type}_network_config", config)
                        network[:auto_config] = config[:auto_config]
                        networks << network
                    end
        
                    if !adapters.empty?
                        # Enable the adapters
                        @logger.info("Enabling adapters...")
                        env[:ui].output(I18n.t("vagrant.actions.vm.network.preparing"))
                        adapters.each do |adapter|
                            env[:ui].detail(I18n.t(
                            "vagrant.virtualbox.network_adapter",
                            adapter: adapter[:adapter].to_s,
                            type: adapter[:type].to_s,
                            extra: "",
                            ))
                        end
                    end

                    # Continue the middleware chain.
                    @app.call(env)
                    
                    # If we have networks to configure, then we configure it now, since
                    # that requires the machine to be up and running.
                    if !adapters.empty? && !networks.empty?
                        assign_interface_numbers(networks, adapters)
            
                        # Only configure the networks the user requested us to configure
                        networks_to_configure = networks.select { |n| n[:auto_config] }
                        if !networks_to_configure.empty?
                            @logger.debug("networks_to_configure: #{networks_to_configure}")
                            env[:ui].info I18n.t("vagrant.actions.vm.network.configuring")
                            env[:machine].guest.capability(:configure_networks, networks_to_configure)
                        end
                    end
                end
                
                def bridged_config(options)
                    return {
                      auto_config:                     true,
                      bridge:                          nil,
                      mac:                             nil,
                      nic_type:                        nil,
                      use_dhcp_assigned_default_route: false
                    }.merge(options || {})
                  end

                def bridged_adapter(config)
                    # Given the choice we can now define the adapter we're using
                    return {
                        adapter:     config[:adapter],
                        type:        :bridged,
                        bridge:      config[:bridge],
                        mac_address: config[:mac],
                        nic_type:    config[:nic_type]
                    }
                end

                def bridged_network_config(config)
                    if config[:ip]
                      options = {
                          auto_config: true,
                          mac:         nil,
                          netmask:     "255.255.255.0",
                          type:        :static
                      }.merge(config)
                      options[:type] = options[:type].to_sym
                      return options
                    end
          
                    return {
                      type: :dhcp,
                      use_dhcp_assigned_default_route: config[:use_dhcp_assigned_default_route]
                    }
                end

                def intnet_config(options)
                    return {
                      type: "static",
                      ip: nil,
                      netmask: "255.255.255.0",
                      adapter: nil,
                      mac: nil,
                      intnet: nil,
                      auto_config: true
                    }.merge(options || {})
                end
          
                def intnet_adapter(config)
                    intnet_name = config[:intnet]
                    intnet_name = "intnet" if intnet_name == true
            
                    return {
                        adapter: config[:adapter],
                        type: :intnet,
                        mac_address: config[:mac],
                        nic_type: config[:nic_type],
                        intnet: intnet_name,
                    }
                end
        
                def intnet_network_config(config)
                    return {
                        type: config[:type],
                        ip: config[:ip],
                        netmask: config[:netmask]
                    }
                end
        
                def nat_config(options)
                    return {
                        auto_config: false
                    }
                end
        
                def nat_adapter(config)
                    return {
                        adapter: config[:adapter],
                        type:    :nat,
                    }
                end
        
                def nat_network_config(config)
                    return {}
                end
                
                def hostonly_config(options)
                    return {
                      auto_config:                     true,
                      bridge:                          nil,
                      mac:                             nil,
                      nic_type:                        nil,
                      use_dhcp_assigned_default_route: false
                    }.merge(options || {})
                end

                def hostonly_adapter(config)
                    return {
                        adapter:     config[:adapter],
                        type:        :hostonly,
                        bridge:      config[:bridge],
                        mac_address: config[:mac],
                        nic_type:    config[:nic_type]
                    }
                end
                
                def hostonly_network_config(config)
                    if config[:ip]
                      options = {
                          auto_config: true,
                          mac:         nil,
                          netmask:     "255.255.255.0",
                          type:        :static
                      }.merge(config)
                      options[:type] = options[:type].to_sym
                      return options
                    end
          
                    return {
                      type: :dhcp,
                      use_dhcp_assigned_default_route: config[:use_dhcp_assigned_default_route]
                    }
                end

                def get_num_ethernet_cards(env)
                    config = @env[:machine].provider_config

					# Make a first pass to assign interface numbers by adapter location
                    result = Vagrant::Util::Subprocess.execute("ssh", "#{config.user}@#{config.host}", "vim-cmd vmsvc/get.summary '[#{config.datastore}] #{config.name}/#{config.name}.vmx'")
                    
                    if result.exit_code != 0
                        raise Errors::VmRegisteringError, stderr: result.stderr
                    end

                    m = /numEthernetCards = ([0123456789]+),/m.match(result.stdout)

                    return 0 if m.nil?

                    return m[1].to_i
                end

                def find_adapter_id(adapters, id)
                    adapters.each do |adapter|
                        if adapter[:adapter].to_i == id
                            return adapter
                        end
                    end

                    return nil
                end
                #-----------------------------------------------------------------
				# Misc. helpers
				#-----------------------------------------------------------------
				# Assigns the actual interface number of a network based on the
				# enabled NICs on the virtual machine.
				#
				# This interface number is used by the guest to configure the
				# NIC on the guest VM.
				#
				# The networks are modified in place by adding an ":interface"
				# field to each.
				def assign_interface_numbers(networks, adapters)        
                    @logger.info("Entered assign_interface_numbers...")
                    @logger.debug("networks: #{networks}")
                    @logger.debug("adapters: #{adapters}")
                                        
                    numEthernetCards = get_num_ethernet_cards(@env)

                    @logger.info("Found #{numEthernetCards} ethernet card...")

                    if numEthernetCards < networks.length
                        raise Vagrant::Errors::VirtualBoxNoRoomForHighLevelNetwork
                    end

                    interface = 1

                    networks.each do |network|
                        auto_config = network[:auto_config];

                        if auto_config.nil? || auto_config
                            adapter_id = network[:adapter].to_i
                            @logger.debug("adapter_id: #{adapter_id}")

                            adapter = find_adapter_id(adapters, adapter_id)
                            @logger.debug("adapter: #{adapter}")
                            
                            if ! adapter.nil?
                                adapter_type = adapter[:type]
                                @logger.debug("adapter_type: #{adapter_type}")

                                if adapter_type === :hostonly
                                    network[:interface] = 0
                                else
                                    network[:interface] = interface
                                    interface += 1
                                end
                            end
                        end
                    end

                    # we use old name "eth0, eth1..."
                    #(1..numEthernetCards - 1).each do |i|
                    #    network = networks[i - 1]
                    #    network[:interface] = i
                    #end
				end
            end
        end
    end
end
