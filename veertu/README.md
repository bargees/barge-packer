# Barge Packer for Veertu

Builds the following image with [Barge OS](https://github.com/bargees/barge-os)

- barge-veertu.box (13MB) : Vagrant box with barge.iso and 20GB HDD

The raw Barge images are at https://github.com/bargees/barge-os.

## Features

- Disable TLS of Docker for simplicity
- Expose the official IANA registered Docker port 2375
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

- [Veertu](https://veertu.com/)
- [Vagrant](https://www.vagrantup.com/)
- [vagrant-veertu](https://rubygems.org/gems/vagrant-veertu/)

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
  config.vm.provider :veertu
  config.vm.box = "ailispaw/barge"

  if Vagrant.has_plugin?("vagrant-triggers")
    PWD=`pwd`.strip
    UID=`id -u`.strip
    GID=`id -g`.strip
    NET_ADDR="192.168.64.0"
    NET_MASK="255.255.255.0"
    EXPORTS="\"#{PWD}\" -network #{NET_ADDR} -mask #{NET_MASK} -alldirs -mapall=#{UID}:#{GID}"

    config.trigger.before [:up] do
      info "Add an entry into /etc/exports"
      run "sudo sh -c 'echo #{EXPORTS.dump.dump} >> /etc/exports'"
      run "sudo nfsd restart"
    end

    config.vm.provision :shell, run: "always" do |sh|
      sh.inline = <<-EOT
        if ! mountpoint -q '/vagrant'; then
          mkdir -p '/vagrant'
          mount -o nolock,vers=3,noatime,actimeo=1 '192.168.64.1:#{PWD}' '/vagrant'
        fi
        pkg install bindfs
        if mountpoint -q '/vagrant' && ! mountpoint -q '#{PWD}'; then
          mkdir -p '#{PWD}'
          bindfs --map=#{UID}/bargee:@#{GID}/@bargees '/vagrant' '#{PWD}'
        fi
      EOT
    end

    config.trigger.after [:destroy] do
      info "Remove the entry from /etc/exports"
      run "sudo touch /etc/exports"
      run "sudo sed -E -e '\\\\|^#{EXPORTS}$|d' -i.bak /etc/exports"
      run "sudo nfsd restart"
    end
  end
end
```

## License

Copyright (c) 2015-2016 A.I. &lt;ailis@paw.zone&gt;

Licensed under the GNU General Public License, version 2 (GPL-2.0)  
http://opensource.org/licenses/GPL-2.0
