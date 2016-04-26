# Barge Packer for QEMU/KVM/Xen

Build a qcow2 file with [Barge](https://github.com/bargees/barge)

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
$ git clone https://github.com/bargees/barge-packer.git
$ cd barge-packer
$ make qemu
```

## Boot up

```
$ contrib/qemu/qemu.sh

Welcome to Barge barge /dev/ttyS0
barge login: 
```

## Logging in

- ID: bargee
- Password: bargee


### form another console
```
$ ssh -p 2222 bargee@localhost -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
$ bargee@localhost's password: 
Welcome to Barge 2.0.0, Docker version 1.9.1, build 66c06d0-stripped
[bargee@barge ~]$ 
```

## Shutting Down

Use `shutdown` command to shut down in the VM.

```
[bargee@barge ~]$ sudo shutdown
shutdown[303]: Executing shutdown scripts in /etc/init.d
Stopping crond... OK
docker[311]: Loading /etc/default/docker
docker[311]: Stopping Docker daemon
Stopping sshd... OK
Saving random seed... done.
shutdown[303]: poweroff
```


## Using Docker

```
$ docker info
Containers: 0
Images: 0
Server Version: 1.9.1
Storage Driver: overlay
 Backing Filesystem: extfs
Execution Driver: native-0.2
Logging Driver: json-file
Kernel Version: 4.4.8-barge
Operating System: Barge 2.0.0
CPUs: 1
Total Memory: 999.2 MiB
Name: barge
ID: XLUR:UAG3:5H7O:BA63:5PBE:AVNY:GW4T:A3JP:2RID:4Q4M:SZOS:HY2E
Debug mode (server): true
 File Descriptors: 12
 Goroutines: 18
 System Time: 2016-04-26T21:42:18.905175024Z
 EventsListeners: 0
 Init SHA1:
 Init Path: /opt/bin/docker
 Docker Root Dir: /mnt/vda2/var/lib/docker
```
