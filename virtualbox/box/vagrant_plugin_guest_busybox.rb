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
          comm = machine.communicate

          commands   = []
          entries    = []

          networks.each do |network|
            network[:device] = "eth#{network[:interface]}"

            if network[:type] == :dhcp
              entry = TemplateRenderer.render("network_#{network[:type]}",
                template_root: __dir__,
                options: network,
              )
            else
              entry = TemplateRenderer.render("guests/debian/network_#{network[:type]}",
                options: network,
              )
            end
            entries << entry
          end

          Tempfile.open("vagrant-barge-configure-networks") do |f|
            f.binmode
            f.write(entries.join("\n"))
            f.fsync
            f.close
            comm.upload(f.path, "/tmp/vagrant-network-entry")
          end

          networks.each do |network|
            # Ubuntu 16.04+ returns an error when downing an interface that
            # does not exist. The `|| true` preserves the behavior that older
            # Ubuntu versions exhibit and Vagrant expects (GH-7155)
            commands << "/sbin/ifdown '#{network[:device]}' || true"
            commands << "/sbin/ip addr flush dev '#{network[:device]}'"
          end

          # Reconfigure /etc/network/interfaces.
          commands << <<-EOH.gsub(/^ {12}/, "")
            # Remove any previous network modifications from the interfaces file
            sed -e '/^#VAGRANT-BEGIN/,$ d' /etc/network/interfaces \\
              > /tmp/vagrant-network-interfaces.pre
            sed -ne '/^#VAGRANT-END/,$ p' /etc/network/interfaces | \\
              awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }' | \\
              sed -e '/^#VAGRANT-END/,$ d' | \\
              awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }' \\
              > /tmp/vagrant-network-interfaces.post

            cat \\
              /tmp/vagrant-network-interfaces.pre \\
              /tmp/vagrant-network-entry \\
              /tmp/vagrant-network-interfaces.post \\
              > /etc/network/interfaces

            rm -f /tmp/vagrant-network-interfaces.pre
            rm -f /tmp/vagrant-network-entry
            rm -f /tmp/vagrant-network-interfaces.post
          EOH

          # Bring back up each network interface, reconfigured.
          networks.each do |network|
            commands << "/sbin/ifup '#{network[:device]}'"
          end

          # Run all the commands in one session to prevent partial configuration
          # due to a severed network.
          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end

# Skip checking nfs client, because mount supports nfs.
begin  # Vagrant <= v1.8.4
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
rescue TypeError, LoadError => e # Vagrant >= v1.8.5
  require Vagrant.source_root.join("plugins/guests/linux/cap/nfs.rb")
  module VagrantPlugins
    module GuestLinux
      module Cap
        class NFS
          def self.nfs_client_installed(machine)
            true
          end
        end
      end
    end
  end
end
