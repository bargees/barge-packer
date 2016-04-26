# Configure Docker Daemon with TLS Support

You need some steps to configure Docker daemon with TLS, because Barge has no TLS support by default.

## Scenario

1. Boot up a Barge VM without TLS
1. Download [generate_cert](https://github.com/SvenDowideit/generate_cert)
1. Generate certificates with generate_cert
1. Set TLS parameters for Docker daemon into /etc/default/docker.
1. Restart the Docker daemon

## Automation with Vagrant

```ruby
Vagrant.configure(2) do |config|
  config.vm.define "barge-secure"

  config.vm.box = "ailispaw/barge"

  config.vm.network :forwarded_port, guest: 2375, host: 2375, auto_correct: true, disabled: true
  config.vm.network :forwarded_port, guest: 2376, host: 2376, auto_correct: true

  config.vm.synced_folder ".", "/vagrant"

  config.vm.provision :shell, path: "generate_certs.sh"

  config.vm.provision :shell do |sh|
    sh.privileged = false
    sh.inline = <<-EOT
      cp -R ~/.docker /vagrant/
      sudo /etc/init.d/docker restart
    EOT
  end
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
 Version:      1.9.1
 API version:  1.21
 Go version:   go1.4.3
 Git commit:   a34a1d5
 Built:        Fri Nov 20 17:56:04 UTC 2015
 OS/Arch:      darwin/amd64

Server:
 Version:      1.9.1
 API version:  1.21
 Go version:   go1.4.3
 Git commit:   66c06d0-stripped
 Built:        Sun Jan 24 07:17:18 UTC 2016
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
