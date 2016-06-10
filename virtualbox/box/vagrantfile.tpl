require_relative "vagrant_plugin_guest_busybox.rb"
require_relative "mount_virtualbox_shared_folder.rb"
require_relative "mount_nfs.rb"

Vagrant.configure("2") do |config|
  config.ssh.username = "bargee"

  # Forward the Docker port
  config.vm.network :forwarded_port, guest: 2375, host: 2375, auto_correct: true

  # Disable synced folder by default
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider :virtualbox do |vb|
    vb.check_guest_additions = false

    vb.customize "pre-boot", [
      "storageattach", :id,
      "--storagectl", "SATA Controller",
      "--port", "1",
      "--device", "0",
      "--type", "dvddrive",
      "--medium", File.expand_path("../barge.iso", __FILE__),
    ]
  end
end
