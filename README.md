# DockerRoot Packer for VirtualBox and QEMU

This builds the following images with [DockerRoot](https://github.com/ailispaw/docker-root)

- docker-root.iso (14MB) : LiveCD image with VirtualBox Guest Addtions
- docker-root.box (13.7MB) : Vagrant box with docker-root.iso and 40GB HDD
- docker-root.qcow2 (15.8MB) : qcow2 image with docker-root.img and 40GB HDD

The raw docker-root images are at https://github.com/ailispaw/docker-root.

## Features

- Disable TLS of Docker for simplicity
- In .box and .qcow2
  - Expose the official IANA registered Docker port 2375
  - 40 GB persistent disk image
- With Vagrant
  - Forward the official IANA registered Docker port 2375
  - Support NFS synced folder
  - Support VirtualBox Shared Folder
  - Support Docker provisioner

Note) Pay attention to **exposing the port 2375 without TLS**, as you see the above features.

## Requirements to build

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- [Packer](https://packer.io/)
- [QEMU](http://www.qemu.org) to build docker-root.qcow2  
  Cf.) https://github.com/ailispaw/docker-root-packer/tree/master/contrib/qemu

## Vagrant up

```bash
$ vagrant box add ailispaw/docker-root
$ vagrant init -m ailispaw/docker-root
$ vagrant up
```

## Vagrantfile

```ruby
# A dummy plugin for DockerRoot to set hostname and network correctly at the very first `vagrant up`
module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") { Cap::ChangeHostName }
      guest_capability("linux", "configure_networks") { Cap::ConfigureNetworks }
    end
  end
end

Vagrant.configure(2) do |config|
  config.vm.define "docker-root"

  config.vm.box = "ailispaw/docker-root"
  config.vm.box_version = ">= 1.2.8"

  config.vm.synced_folder ".", "/vagrant"

  # for NFS synced folder
  # config.vm.network "private_network", ip: "192.168.33.10"
  # config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["nolock", "vers=3", "udp"]

  # for RSync synced folder
  # config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__args: ["--verbose", "--archive", "--delete", "--copy-links"]

  if Vagrant.has_plugin?("vagrant-triggers") then
    config.trigger.after [:up, :resume] do
      info "Adjusting datetime after suspend and resume."
      run_remote "sudo sntp -4sSc pool.ntp.org; date"
    end
  end

  # Adjusting datetime before provisioning.
  config.vm.provision :shell, run: "always" do |sh|
    sh.inline = "sntp -4sSc pool.ntp.org; date"
  end

  config.vm.provision :docker do |d|
    d.pull_images "busybox"
    d.run "simple-echo",
      image: "busybox",
      args: "-p 8080:8080 -v /usr/bin/dumb-init:/dumb-init:ro --entrypoint=/dumb-init",
      cmd: "nc -p 8080 -l -l -e echo hello world!"
  end

  config.vm.network :forwarded_port, guest: 8080, host: 8080
end
```

## License

Copyright (c) 2015-2016 A.I. &lt;ailis@paw.zone&gt;

Licensed under the GNU General Public License, version 2 (GPL-2.0)  
http://opensource.org/licenses/GPL-2.0
