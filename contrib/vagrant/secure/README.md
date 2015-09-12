# Configure Docker Daemon with TLS Support

You need some steps to configure Docker daemon with TLS, because DockerRoot has no TLS support by default.

## Scenario

1. Boot up a DockerRoot VM without TLS
1. Download [generate_cert](https://github.com/SvenDowideit/generate_cert)
1. Generate certificates with generate_cert
1. Set TLS parameters for Docker daemon into /var/lib/docker-root/profile.
1. Reboot the VM

## Automation with Vagrant

```ruby
require_relative "vagrant_plugin_provisioner_reload.rb"

Vagrant.configure(2) do |config|
  config.vm.define "docker-root-secure"

  config.vm.box = "ailispaw/docker-root"

  config.vm.network :forwarded_port, guest: 2375, host: 2375, auto_correct: true, disabled: true
  config.vm.network :forwarded_port, guest: 2376, host: 2376, auto_correct: true

  config.vm.synced_folder ".", "/vagrant"

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

  config.vm.provision :shell, path: "generate_certs.sh"

  config.vm.provision :shell do |sh|
    sh.privileged = false
    sh.inline = <<-EOT
      cp -R ~/.docker /vagrant/
    EOT
  end

  config.vm.provision :reload
end
```

```
$ vagrant up
```

You can get certificates for Docker client at `./.docker/`.

```
$ export DOCKER_HOST=tcp://localhost:2376
$ export DOCKER_CERT_PATH=./.docker
$ export DOCKER_TLS_VERIFY=true
$ docker version
Client:
 Version:      1.8.2
 API version:  1.20
 Go version:   go1.4.2
 Git commit:   0a8c2e3
 Built:        Thu Sep 10 19:10:10 UTC 2015
 OS/Arch:      darwin/amd64

Server:
 Version:      1.8.2
 API version:  1.20
 Go version:   go1.4.2
 Git commit:   0a8c2e3
 Built:        Thu Sep 10 19:10:10 UTC 2015
 OS/Arch:      linux/amd64
```

## Licenses

- generate_certs.sh based on [boot2docker](https://github.com/boot2docker/boot2docker/blob/master/rootfs/rootfs/usr/local/etc/init.d/docker)  
  Copyright 2014 Docker, Inc.  
  Licensed under the Apache License, Version 2.0  
  https://github.com/boot2docker/boot2docker/blob/master/LICENSE

- [generate_cert](https://github.com/SvenDowideit/generate_cert)  
  Copyright 2014 Sven Dowideit  
  Licensed under the Apache License, Version 2.0  
  https://github.com/SvenDowideit/generate_cert/blob/master/LICENSE

- [Vagrant Reload Provisioner](https://github.com/aidanns/vagrant-reload)  
  Copyright (c) 2013 Aidan Nagorcka-Smith  
  Licensed under the MIT license  
  https://github.com/aidanns/vagrant-reload/blob/master/LICENSE.txt
