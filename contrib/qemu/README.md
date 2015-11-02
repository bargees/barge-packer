# DockerRoot Packer for QEMU/KVM/Xen

Build a qcow2 file with [DockerRoot](https://github.com/ailispaw/docker-root)

## Features

- Disable TLS of Docker for simplicity
- Expose and forward the official IANA registered Docker port 2375
- 40 GB persistent disk
- 14 MB

## Requirements

- [QEMU](http://www.qemu.org)
- [Packer](https://packer.io/)

## Building

```
$ git clone https://github.com/ailispaw/docker-root-packer.git
$ cd docker-root-packer
$ make qemu
```

## Boot up

```
$ contrib/qemu/qemu.sh

Welcome to DockerRoot docker-root /dev/ttyS0
docker-root login: 
```

## Logging in

- ID: docker
- Password: docker


### form another console
```
$ ssh -p 2222 docker@localhost -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
$ docker@localhost's password: 
Welcome to DockerRoot version 1.0.2, Docker version 1.8.2, build 0a8c2e3
[docker@docker-root ~]$ 
```

## Shutting Down

Use `shutdown` command to shut down in the VM.

```
[docker@docker-root ~]$ sudo shutdown
shutdown[290]: Executing shutdown scripts in /etc/init.d
Saving random seed... done.
shutdown[290]: poweroff
```


## Using Docker

```
$ docker info
Containers: 0
Images: 0
Storage Driver: overlay
 Backing Filesystem: extfs
Execution Driver: native-0.2
Logging Driver: json-file
Kernel Version: 4.1.6-docker-root
Operating System: DockerRoot v1.0.2
CPUs: 1
Total Memory: 999.8 MiB
Name: docker-root
ID: 6HNI:YYE5:Y5PL:O3KY:DGDU:Q2EO:OVYB:EXUV:Q57N:GKKV:4BH6:BC4X
Debug mode (server): true
File Descriptors: 11
Goroutines: 16
System Time: 2015-09-11T10:10:16.335650489Z
EventsListeners: 0
Init SHA1:
Init Path: /bin/docker
Docker Root Dir: /mnt/vda2/var/lib/docker
```
