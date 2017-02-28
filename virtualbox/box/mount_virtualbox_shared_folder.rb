require Vagrant.source_root.join("plugins/guests/linux/cap/mount_virtualbox_shared_folder.rb")

require "shellwords"

require "vagrant/util/retryable"

module VagrantPlugins
  module GuestLinux
    module Cap
      class MountVirtualBoxSharedFolder
        @@logger = Log4r::Logger.new("vagrant::guest::linux::mount_virtualbox_shared_folder")

        extend Vagrant::Util::Retryable

        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          guest_path = Shellwords.escape(guestpath)

          @@logger.debug("Mounting #{name} (#{options[:hostpath]} to #{guestpath})")

          if options[:owner].to_i.to_s == options[:owner].to_s
            mount_uid = options[:owner]
          else
            mount_uid = "`id -u #{options[:owner]}`"
          end

          if options[:group].to_i.to_s == options[:group].to_s
            mount_gid = options[:group]
          else
            if options[:owner] == options[:group]
              mount_gid = "`id -g #{options[:owner]}`"
            else
              mount_gid = "`grep -w ^#{options[:group]} /etc/group | cut -d: -f3`"
            end
          end

          mount_options = options.fetch(:mount_options, [])
          mount_options += ["uid=#{mount_uid}", "gid=#{mount_gid}"]
          mount_options = mount_options.join(',')
          mount_command = "mount.vboxsf -o #{mount_options} #{name} #{guest_path}"

          # Create the guest path if it doesn't exist
          machine.communicate.sudo("mkdir -p #{guest_path}")

          # Attempt to mount the folder. We retry here a few times because
          # it can fail early on.
          stderr = ""
          retryable(on: Vagrant::Errors::VirtualBoxMountFailed, tries: 3, sleep: 5) do
            machine.communicate.sudo(mount_command,
              error_class: Vagrant::Errors::VirtualBoxMountFailed,
              error_key: :virtualbox_mount_failed,
              command: mount_command,
              output: stderr,
            ) { |type, data| stderr = data if type == :stderr }
          end

          # Chown the directory to the proper user. We skip this if the
          # mount options contained a readonly flag, because it won't work.
          if !options[:mount_options] || !options[:mount_options].include?("ro")
            chown_command = "chown #{mount_uid}:#{mount_gid} #{guest_path}"
            machine.communicate.sudo(chown_command)
          end
        end

        def self.unmount_virtualbox_shared_folder(machine, guestpath, options)
          guest_path = Shellwords.escape(guestpath)

          result = machine.communicate.sudo("umount #{guest_path}", error_check: false)
          if result == 0
            machine.communicate.sudo("rmdir #{guest_path}", error_check: false)
          end
        end
      end
    end
  end
end
