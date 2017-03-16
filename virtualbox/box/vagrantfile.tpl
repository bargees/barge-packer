@ui = Vagrant::UI::Colored.new
require Vagrant.source_root.join("plugins/providers/virtualbox/driver/meta.rb")
meta = VagrantPlugins::ProviderVirtualBox::Driver::Meta.new
if Gem::Version.new('5.1') > Gem::Version.new(meta.version)
  @ui.warn "Now Barge box supports VirtualBox v5.1."
  if Gem::Version.new('5.0.32') > Gem::Version.new(meta.version)
    @ui.warn "To use the Barge box on VirtualBox properly,"
    @ui.warn "you must upgrade VirtualBox(v#{meta.version}) to v5.0.32/v5.1.6 or later."
    abort
  else
    @ui.warn "You are encouraged to upgrade VirtualBox(v#{meta.version}) to v5.1.6 or later."
  end
elsif Gem::Version.new('5.1.6') > Gem::Version.new(meta.version)
  @ui.warn "To use the Barge box on VirtualBox properly,"
  @ui.warn "you must upgrade VirtualBox(v#{meta.version}) to v5.1.6 or later."
  abort
end

require_relative "vagrant_plugin_guest_busybox.rb"
if (Vagrant::Errors::VirtualBoxMountFailed rescue false) # Vagrant >= 1.8.5
  require_relative "mount_virtualbox_shared_folder.rb"
end
if (Vagrant::Errors::LinuxNFSMountFailed rescue false) # Vagrant <= 1.8.4
  require_relative "mount_nfs.rb"
end

Vagrant.configure("2") do |config|
  config.vm.guest = "linux"

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
      "--medium", File.expand_path("../barge-vbox.iso", __FILE__),
    ]
  end
end
