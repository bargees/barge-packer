# Barge Packer for VirtualBox

Builds the following images with [Barge OS](https://github.com/bargees/barge-os)

- barge.iso (14MB) : LiveCD image with VirtualBox Guest Addtions
- barge.box (13MB) : Vagrant box with barge.iso and 40GB HDD

The raw Barge images are at https://github.com/bargees/barge-os.

## Features

- Disable TLS of Docker for simplicity
- Expose the official IANA registered Docker port 2375
- Support NFS synced folder
- Support VirtualBox Shared Folder
- Support VirtualBox Time Sync
- Support Docker provisioner

Note) Pay attention to **exposing the port 2375 without TLS**, as you see the above features.

## Requirements to build

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- [Packer](https://packer.io/)

## Building

```
$ git clone https://github.com/bargees/barge-packer.git
$ cd barge-packer/virtualbox
$ make
```

## Vagrant up

```bash
$ vagrant box add ailispaw/barge
$ vagrant init -m ailispaw/barge
$ vagrant up
```

## Vagrantfile

```ruby
# A dummy plugin for Barge to set hostname and network correctly at the very first `vagrant up`
module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") { Cap::ChangeHostName }
      guest_capability("linux", "configure_networks") { Cap::ConfigureNetworks }
    end
  end
end

Vagrant.configure(2) do |config|
  config.vm.define "barge"

  config.vm.box = "ailispaw/barge"

  config.vm.synced_folder ".", "/vagrant"

  # for NFS synced folder
  # config.vm.network :private_network, ip: "192.168.33.10"
  # config.vm.synced_folder ".", "/vagrant", type: "nfs",
  #   mount_options: ["nolock", "vers=3", "udp", "noatime", "actimeo=1"]

  # for RSync synced folder
  # config.vm.synced_folder ".", "/vagrant", type: "rsync",
  #   rsync__args: ["--verbose", "--archive", "--delete", "--copy-links"]

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
