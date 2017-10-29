require "i18n"

module VagrantPlugins
  module ESXi
    module Action
      class Import

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::plugins::esxi::action::import")
          @app = app
        end

        def call(env)
          config = env[:machine].provider_config
          ovf_file = ""
          dst = config.name
          dst_dir = "/vmfs/volumes/#{config.datastore}/#{dst}"
          dst_vmx = "#{dst_dir}/#{dst}.vmx"
          dst_vmx_bak = "#{dst_dir}/#{dst}.vmx.bak"
          
          env[:ui].info(I18n.t("vagrant_esxi.importing"))

          if system("ssh #{config.user}@#{config.host} test -e #{dst_dir}")
            raise Errors::VmImageExistsError, :message => "#{dst} exists!"
          end
          
          # Find first OVF/OVA file
          env[:machine].box.directory.each_child(false) do |child|
            if child.extname === ".ovf" || child.extname === ".ova" || child.extname === ".vmx"
                ovf_file = env[:machine].box.directory.join(child.to_s).to_s
                break
            end
          end

          ovf_cmd = ["ovftool", "--noSSLVerify", "--acceptAllEulas", "--datastore=#{config.datastore}", "--network=#{config.network}", "--name=#{config.name}", "#{ovf_file}", "vi://#{config.user}:#{config.password}@#{config.host}"]

          result = Vagrant::Util::Subprocess.execute(*ovf_cmd)
          
          if result.exit_code != 0
            raise Errors::OvfError,
              :ovf_file => ovf_file,
              :stderr => result.stderr
          end            
        
          echo = [
          ]

          # Strip VMX config
          patterns = ""

          # Change memSize
          unless config.memory_mb.nil? || config.memory_mb == ''
            patterns += " -e '^memSize'"
            echo << "memSize = \"#{config.memory_mb}\""
          end

          # Change numvcpus
          unless config.cpu_count.nil? || config.cpu_count == ''
            patterns += " -e '^numvcpus'"
            echo << "numvcpus = \"#{config.cpu_count}\""
          end

          config.vmx.each do |key, value|
            patterns += " -e '^#{key}'"
            echo << "#{key} = \"#{value}\""
          end
          
          # if we mofy the vmx
          if ! patterns.empty? 
            
            # Create final command to patch the vmx file
            cmd = [
              "mv #{dst_vmx} #{dst_vmx_bak}",
              "grep -v #{patterns} #{dst_vmx_bak} > '#{dst_vmx}'"
            ]
   
            echo.each { |item| cmd << "echo '#{item}' >> '#{dst_vmx}'" }
            cmd << "rm #{dst_vmx_bak}"
            cmd << "chmod +x #{dst_vmx}"

            cmd.each do |line|
              result = Vagrant::Util::Subprocess.execute("ssh", "#{config.user}@#{config.host}", "#{line}")

              if result.exit_code != 0
                raise Errors::VmRegisteringError, stderr: result.stderr
              end
            end
          end

          # Expand main drive
          unless config.expand_hd.nil? || config.expand_hd == ''
            env[:ui].info(I18n.t("vagrant_esxi.expand_drive"))

            #cmd = "vmkfstools -X #{dsk_size} '[#{config.datastore}] #{config.name}/#{config.name}.vmdk'"
            cmd = "vmkfstools '/vmfs/volumes/#{config.datastore}/#{config.name}/#{config.name}.vmdk' -X #{config.expand_hd}M"
            
            result = Vagrant::Util::Subprocess.execute("ssh", "#{config.user}@#{config.host}", "#{cmd}")
            
            if result.exit_code != 0
                raise Errors::VMHdExpandError, stderr: result.stderr
            end
          end

          # Register VM
          
          env[:ui].info(I18n.t("vagrant_esxi.registering"))

          result = Vagrant::Util::Subprocess.execute("ssh", "#{config.user}@#{config.host}", "vim-cmd vmsvc/reload '[#{config.datastore}] #{config.name}/#{config.name}.vmx'")

          if result.exit_code != 0
            raise Errors::VmRegisteringError, stderr: result.stderr
          end

          env[:machine].id = "[#{config.datastore}]\\ #{config.name}/#{config.name}.vmx"
          
          # Add more nic
          numEthernetCards = get_num_ethernet_cards(config)
          numOfNetworks = 0;

          network_types = []
          nic_types = []
          current = 0

          env[:machine].config.vm.networks.each do |network_type, options|
            @logger.debug("network_type: #{network_type}, options:#{options}")
            #next if network_type != :private_network && network_type != :public_network
            next if network_type != :public_network
            
            if (network_type === :private_network)
              network_types << config.network
            else
              if options[:network].nil?
                network_types << config.config.network_public[current]
                current += 1
              else
                network_types << options[:network]
              end
            end

            if (options[:nic_type].nil?)
              nic_types << "e1000"
            else
              nic_types << options[:nic_type]
            end
            
            numOfNetworks += 1
          end

          needCard = numOfNetworks - numEthernetCards + 1;

          @logger.info("Found #{numEthernetCards} ethernet card, need #{numOfNetworks} network, need #{needCard} more card")

          (1..needCard).each do |i|            
            env[:ui].info(I18n.t("vagrant_esxi.add_nic"))

            network_type = network_types[i - 1]
            nic_type = nic_types[i -1]

            cmd = "vim-cmd vmsvc/devices.createnic '[#{config.datastore}] #{config.name}/#{config.name}.vmx' #{nic_type} '#{network_type}'"
          
            result = Vagrant::Util::Subprocess.execute("ssh", "#{config.user}@#{config.host}", "#{cmd}")
            
            if result.exit_code != 0
              raise Errors::VMNicCreateError, network: network_type, stderr: result.stderr
            end
          end
 
          # Add second drive
          unless config.add_hd.nil? || config.add_hd == ''
            env[:ui].info(I18n.t("vagrant_esxi.add_drive"))

            dsk_size = config.add_hd * 1024

            cmd = "vim-cmd vmsvc/device.diskadd '[#{config.datastore}] #{config.name}/#{config.name}.vmx' #{dsk_size} 0 1 #{config.datastore}"

            result = Vagrant::Util::Subprocess.execute("ssh", "#{config.user}@#{config.host}", "#{cmd}")
 
            if result.exit_code != 0
                raise Errors::VMHdCreateError, stderr: result.stderr
            end
          end
            
          @app.call env
        end

        def get_num_ethernet_cards(config)
          # Make a first pass to assign interface numbers by adapter location
          result = Vagrant::Util::Subprocess.execute("ssh", "#{config.user}@#{config.host}", "vim-cmd vmsvc/get.summary '[#{config.datastore}] #{config.name}/#{config.name}.vmx'")
          
          if result.exit_code != 0
            raise Errors::VmRegisteringError, stderr: result.stderr
          end

          m = /numEthernetCards = ([0123456789]+),/m.match(result.stdout)

          return 0 if m.nil?

          return m[1].to_i
      end
    end
  end
  end
end
