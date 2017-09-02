require "i18n"
require "open3"

module VagrantPlugins
  module ESXi
    module Action
      class Create

        def initialize(app, env)
          @app = app
        end

        def call(env)
          config = env[:machine].provider_config

          src = env[:machine].config.vm.box
          dst = config.name

          src_dir = "/vmfs/volumes/#{config.datastore}/#{src}"
          dst_dir = "/vmfs/volumes/#{config.datastore}/#{dst}"
          dst_vmx = "#{dst_dir}/#{src}.vmx"
          
          echo = [
            "displayName = \\\"#{dst}\\\""
          ]

          env[:ui].info(I18n.t("vagrant_esxi.creating"))
          raise Errors::VmImageExistsError, :message => "#{dst} exists!" if system("ssh #{config.user}@#{config.host} test -e #{dst_dir}")

          # Strip VMX config
          patterns = " -e '^uuid.location' -e '^uuid.bios' -e '^vc.uuid' -e '^displayName'"

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
          
          grep = "grep -v #{patterns} #{dst_dir}/#{src}.vmx.bak '>' #{dst_dir}/#{src}.vmx"
          
          cmd = [
                 "mkdir -p '#{dst_dir}'",
                 "find '#{src_dir}' -type f \\! -name \\*.iso -exec cp '\\{\\}' #{dst_dir}/ '\\;'",
                 "cd '#{dst_dir}'",
                 "find '#{src_dir}' -type f -name \\*.iso -exec ln -s '\\{\\}' '\\;'",
                 "mv #{dst_vmx} #{dst_vmx}.bak",
                ]
          
          # Create final command
          cmd << grep
          echo.each { |item| cmd << "echo '#{item}' '>>' '#{dst_vmx}'" }
          cmd << "rm #{dst_vmx}.bak"
          cmd << "chmod +x #{dst_vmx}"

          #cmd.each { |value| puts "#{value}" }

          cmd.each do |line|
            #puts "exec:#{line}\n"
            system("ssh #{config.user}@#{config.host} #{line}")
          end

          #system("ssh #{config.user}@#{config.host} " + cmd.join(" '&&' "))

          env[:ui].info(I18n.t("vagrant_esxi.registering"))
          o, s = Open3.capture2("ssh #{config.user}@#{config.host} vim-cmd solo/registervm '#{dst_vmx}'")

          env[:machine].id = "#{config.host}:#{o.chomp}"

          #puts "VMId:#{env[:machine].id}"

          # Add second drive
          unless config.add_hd.nil? || config.add_hd == ''
            env[:ui].info(I18n.t("vagrant_esxi.add_drive"))

            cmd = "vim-cmd vmsvc/device.diskadd '[#{config.datastore}]\\ #{config.name}/#{env[:machine].config.vm.box}.vmx' '#{config.add_hd}M' 0 1 #{config.datastore}"

            system("ssh #{config.user}@#{config.host} #{cmd}")
          end
            
          @app.call env
        end
      end
    end
  end
end
