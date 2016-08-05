# Barge Packer for Veertu

Builds the following image with [Barge OS](https://github.com/bargees/barge-os)

- barge-veertu.box (13MB) : Vagrant box with barge.iso and 20GB HDD

The raw Barge images are at https://github.com/bargees/barge-os.

## Features

- Disable TLS of Docker for simplicity
- Expose the official IANA registered Docker port 2375
- Support NFS synced folder
- Support Docker provisioner
- Veertu seems not to support private_network and synced_folder yet.

Note) Pay attention to **exposing the port 2375 without TLS**, as you see the above features.

## Building

```
$ git clone https://github.com/bargees/barge-packer.git
$ cd barge-packer/veertu
$ make
```

## Requirements to run

- [Vagrant](https://www.vagrantup.com/)
- [Veertu](https://veertu.com/) v1.1.2, v1.1.3
- [vagrant-veertu](https://rubygems.org/gems/vagrant-veertu/) v0.0.12 (for Veertu v1.1.2), v0.0.15 (for Veertu v1.1.3)

## Vagrant up

```bash
$ vagrant plugin install vagrant-veertu
$ vagrant box add --provider veertu ailispaw/barge
$ vagrant init -m ailispaw/barge
$ vagrant up --provider veertu
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
  config.vm.define "barge-veertu"

  config.vm.box = "ailispaw/barge"

  config.vm.synced_folder ".", "/vagrant", type: "nfs",
    mount_options: ["nolock", "vers=3", "udp", "noatime", "actimeo=1"]

  config.vm.provision :docker do |docker|
    docker.pull_images "busybox"
    docker.run "simple-echo",
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
