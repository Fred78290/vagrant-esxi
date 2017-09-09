
module VagrantPlugins
  module ESXi
    module Action
      class GetSshInfo

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::plugins::esxi::ssh_info")
          @app = app
        end

        def call(env)
          env[:machine_ssh_info] = get_ssh_info(env[:esxi_connection], env[:machine])

          @app.call env
        end

        private

        def get_ssh_info(connection, machine)

          config = machine.provider_config

          # In case of multi net, the cards are in reverse order
          result = Vagrant::Util::Subprocess.execute("ssh", "#{config.user}@#{config.host}", "vim-cmd vmsvc/get.guest '[#{config.datastore}] #{config.name}/#{config.name}.vmx'")
          
          # Try to drop IPV6 addresses
          ipAddresses = result.stdout.scan(/^                  ipAddress = "([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})",/)

          if ! ipAddresses.empty?
            @logger.debug("ipAddresses: #{ipAddresses}")

            ipAddresse = ipAddresses[ipAddresses.length - 1][0]

            return {
              :host => ipAddresse,
              :port => 22
            }
          else
            @logger.debug("Doesnt found network card")

            return nil
          end
        end
      end
    end
  end
end
