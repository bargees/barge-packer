# DockerRoot Packer for Vagrant Box

Build a Vagrant box with [DockerRoot](https://github.com/ailispaw/docker-root)

## Features

- Support NFS synced folder
- Support VirtualBox Shared Folder
- Support Docker provisioner
- Disable TLS of Docker for simplicity
- Expose and forward the official IANA registered Docker port 2375
- 40 GB persistent disk
- 12 MB

## Requirements to build

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- [Packer](https://packer.io/)
- [QEMU](www.qemu.org) to build docker-root.qcow2  
  Cf.) https://github.com/ailispaw/docker-root-packer/tree/master/contrib/qemu

## Vagrant up

```
$ vagrant box add ailispaw/docker-root
$ vagrant init -m ailispaw/docker-root
$ vagrant up
```

## Vagrantfile

```
Vagrant.configure(2) do |config|
  config.vm.define "docker-root"

  config.vm.box = "ailispaw/docker-root"

  config.vm.synced_folder ".", "/vagrant"

  # for NFS synced folder
  # config.vm.network "private_network", ip: "192.168.33.10"
  # config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["nolock", "vers=3", "udp"]

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
      args: "-p 8080:8080 --restart=always",
      cmd: "nc -p 8080 -l -l -e echo hello world!"
  end

  config.vm.network :forwarded_port, guest: 8080, host: 8080
end
```
