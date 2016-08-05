vagrant_veertu_path = VagrantPlugins::ProviderVeertu.source_root.join("lib/vagrant-veertu/")

require vagrant_veertu_path.join("driver/version_5_0.rb")
module VagrantPlugins
  module ProviderVeertu
    module Driver
      class Version_5_0 < Base
        def read_vms
          results = {}
          vms = get_vm_list()
          vms.each do |vm|
            results[vm['name']] = vm['id']
          end
          results
        end
      end
    end
  end
end

require vagrant_veertu_path.join("action.rb")
module VagrantPlugins
  module ProviderVeertu
    module Action
      def self.action_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckAccessible
          b.use SetName
          b.use ClearForwardedPorts
          b.use Provision
          b.use EnvSet, port_collision_repair: true
          b.use PrepareForwardedPortCollisionParams
          b.use HandleForwardedPortCollisions

          b.use PrepareNFSValidIds
          b.use SyncedFolderCleanup
          b.use SyncedFolders
          b.use PrepareNFSSettings

          b.use Network
          b.use NetworkFixIPv6
          b.use ForwardPorts
          b.use SetHostname
          b.use SaneDefaults
          b.use Customize, "pre-boot"
          b.use Boot
          b.use Customize, "post-boot"
          b.use WaitForCommunicator, [:starting, :suspending, :running, :stopped]
          b.use Customize, "post-comm"
        end
      end
    end
  end
end

require vagrant_veertu_path.join("action/prepare_nfs_settings.rb")
module VagrantPlugins
  module ProviderVeertu
    module Action
      class PrepareNFSSettings
        def add_ips_to_env!(env)
          host_ip    = nil
          machine_ip = nil

          command = "ip route get 8.8.8.8 | awk 'NR==1 {print $3, $7}'"
          @machine.communicate.sudo command do |_, result|
            host_ip, machine_ip = result.split
          end
          raise Vagrant::Errors::NFSNoHostIP if !host_ip
          raise Vagrant::Errors::NFSNoGuestIP if !machine_ip

          env[:nfs_host_ip]    = host_ip
          env[:nfs_machine_ip] = machine_ip
        end
      end
    end
  end
end
