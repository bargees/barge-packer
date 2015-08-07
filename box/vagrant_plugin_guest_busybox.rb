# Add change_host_name guest capability
module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") do
        Cap::ChangeHostName
      end
    end

    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          new(machine, name).change!
        end

        attr_reader :machine, :new_hostname

        def initialize(machine, new_hostname)
          @machine = machine
          @new_hostname = new_hostname
        end

        def change!
          return unless should_change?

          update_etc_hostname
          update_etc_hosts
          refresh_hostname_service
        end

        def should_change?
          new_hostname != current_hostname
        end

        def current_hostname
          @current_hostname ||= get_current_hostname
        end

        def get_current_hostname
          hostname = ""
          sudo "hostname" do |type, data|
            hostname = data.chomp if type == :stdout && hostname.empty?
          end

          hostname
        end

        def update_etc_hostname
          sudo("echo '#{short_hostname}' > /etc/hostname")
        end

        # /etc/hosts should resemble:
        # 127.0.0.1   localhost
        # 127.0.1.1   host.fqdn.com host.fqdn host
        def update_etc_hosts
          if test("grep '#{current_hostname}' /etc/hosts")
            # Current hostname entry is in /etc/hosts
            ip_address = '([0-9]{1,3}\.){3}[0-9]{1,3}'
            search     = "^(#{ip_address})\\s+#{Regexp.escape(current_hostname)}(\\s.*)?$"
            replace    = "\\1 #{fqdn} #{short_hostname}"
            expression = ['s', search, replace, 'g'].join('@')

            sudo("sed -ri '#{expression}' /etc/hosts")
          else
            # Current hostname entry isn't in /etc/hosts, just append it
            sudo("echo '127.0.1.1 #{fqdn} #{short_hostname}' >>/etc/hosts")
          end
        end

        def refresh_hostname_service
          sudo("hostname -F /etc/hostname")
        end

        def fqdn
          new_hostname
        end

        def short_hostname
          new_hostname.split('.').first
        end

        def sudo(cmd, &block)
          machine.communicate.sudo(cmd, &block)
        end

        def test(cmd)
          machine.communicate.test(cmd)
        end
      end
    end
  end
end

# Add configure_networks guest capability
module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "configure_networks") do
        Cap::ConfigureNetworks
      end
    end

    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|
            # First, remove any previous network modifications
            # from the interface file.
            comm.sudo("sed -e '/^#VAGRANT-BEGIN/,$ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces.pre")
            comm.sudo("sed -ne '/^#VAGRANT-END/,$ p' /etc/network/interfaces | tail -n +2 > /tmp/vagrant-network-interfaces.post")

            # Accumulate the configurations to add to the interfaces file as
            # well as what interfaces we're actually configuring since we use that
            # later.
            interfaces = Set.new
            entries = []
            networks.each do |network|
              interfaces.add(network[:interface])
              entry = TemplateRenderer.render("guests/debian/network_#{network[:type]}",
                                              options: network)

              entries << entry
            end

            # Perform the careful dance necessary to reconfigure
            # the network interfaces
            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entries.join("\n"))
            temp.close

            comm.upload(temp.path, "/tmp/vagrant-network-entry")

            # Bring down all the interfaces we're reconfiguring. By bringing down
            # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
            # SSH never dies.
            interfaces.each do |interface|
              comm.sudo("/sbin/ifdown eth#{interface} 2> /dev/null")
              comm.sudo("/sbin/ip addr flush dev eth#{interface} 2> /dev/null")
            end

            comm.sudo('cat /tmp/vagrant-network-interfaces.pre /tmp/vagrant-network-entry /tmp/vagrant-network-interfaces.post > /etc/network/interfaces')
            comm.sudo('rm -f /tmp/vagrant-network-interfaces.pre /tmp/vagrant-network-entry /tmp/vagrant-network-interfaces.post')

            # Bring back up each network interface, reconfigured
            interfaces.each do |interface|
              comm.sudo("/sbin/ifup eth#{interface}")
            end
          end
        end
      end
    end
  end
end

# Skip checking nfs client, because mount supports nfs.
require Vagrant.source_root.join("plugins/guests/linux/cap/nfs_client.rb")
module VagrantPlugins
  module GuestLinux
    module Cap
      class NFSClient
        def self.nfs_client_installed(machine)
          true
        end
      end
    end
  end
end

# Skip ensure_installed for Docker Provisioner
require Vagrant.source_root.join("plugins/provisioners/docker/installer.rb")
module VagrantPlugins
  module DockerProvisioner
    class Installer
      def ensure_installed
      end
    end
  end
end
