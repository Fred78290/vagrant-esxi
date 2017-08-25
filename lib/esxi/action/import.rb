require "i18n"
require "open3"

module VagrantPlugins
  module ESXi
    module Action
      class Import

        def initialize(app, env)
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

          ovf_cmd = ["ovftool", "--datastore=#{config.datastore}", "--name=#{config.name}", "#{ovf_file}", "vi://#{config.user}:#{config.password}@#{config.host}"]

          r = Vagrant::Util::Subprocess.execute(*ovf_cmd)
          
          if r.exit_code != 0
            raise Errors::OvfError,
              :ovf_file => ovf_file,
              :stderr => r.stderr
          end            
        
          echo = [
          ]

          # Strip VMX config
          patterns = ""

          # Change memSize
          unless config.memory_mb.nil? || config.memory_mb == ''
            patterns += " -e '^memSize'"
            echo << "memSize = \\\"#{config.memory_mb}\\\""
          end

          # Change numvcpus
          unless config.cpu_count.nil? || config.cpu_count == ''
            patterns += " -e '^numvcpus'"
            echo << "numvcpus = \\\"#{config.cpu_count}\\\""
          end

          config.vmx.each do |key, value|
            patterns += " -e '^#{key}'"
            echo << "#{key} = \\\"#{value}\\\""
          end
          
          # if we mofy the vmx
          if ! patterns.empty? 
            
            # Create final command to patch the vmx file
            cmd = [
              "mv #{dst_vmx} #{dst_vmx_bak}",
              "grep -v #{patterns} #{dst_vmx_bak} '>' #{dst_vmx}"
            ]
   
            echo.each { |item| cmd << "echo '#{item}' '>>' '#{dst_vmx}'" }
            cmd << "rm #{dst_vmx_bak}"
            cmd << "chmod +x #{dst_vmx}"

            cmd.each do |line|
              system("ssh #{config.user}@#{config.host} #{line}")
            end
          end

          env[:ui].info(I18n.t("vagrant_esxi.registering"))
          o, s = Open3.capture2("ssh #{config.user}@#{config.host} vim-cmd vmsvc/reload '[#{config.datastore}]\\ #{config.name}/#{config.name}.vmx'")

          env[:machine].id = "[#{config.datastore}]\\ #{config.name}/#{config.name}.vmx"
          
          # Add second drive
          unless config.add_hd.nil? || config.add_hd == ''
            env[:ui].info(I18n.t("vagrant_esxi.add_drive"))

            cmd = "vim-cmd vmsvc/device.diskadd '[#{config.datastore}]\\ #{config.name}/#{config.name}.vmx' '#{config.add_hd}M' 0 1 #{config.datastore}"

            system("ssh #{config.user}@#{config.host} #{cmd}")
          end
            
          @app.call env
        end
      end
    end
  end
end
