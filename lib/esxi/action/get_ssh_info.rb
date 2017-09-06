require "open3"

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
          o, s = Open3.capture2("ssh #{config.user}@#{config.host} vim-cmd vmsvc/get.guest '[#{config.datastore}]\\ #{config.name}/#{config.name}.vmx'")
          
          #@logger.debug(o)

          ipAddresses = o.scan(/^                  ipAddress = "(.*?)",/)

          if ! ipAddresses.empty?
            @logger.debug("ipAddresses: #{ipAddresses}")

            return {
              :host => ipAddresses[ipAddresses.length - 1][0],
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
