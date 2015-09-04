# Resize a Persistent Disk in a DockerRoot Vagrant box

It will convert a persistent disk from VMDK to VDI and resize it.

## How to Use

```
$ vagrant box add ailispaw/docker-root
$ vagrant init -m ailispaw/docker-root
$ vagrant up
$ vagrant ssh -c 'df' -- -T
Filesystem           1K-blocks      Used Available Use% Mounted on
devtmpfs                506580         0    506580   0% /dev
tmpfs                   511944         0    511944   0% /run
cgroup                  511944         0    511944   0% /sys/fs/cgroup
/dev/sda1             38255576     49204  36142504   0% /mnt/sda1
overlay               38255576     49204  36142504   0% /etc
$ curl -OL https://raw.githubusercontent.com/ailispaw/docker-root-packer/master/contrib/vagrant/resizedisk/resize.sh
$ chmod +x resize.sh
$ ./resize.sh default 80000
Stopping the VM...
==> default: Attempting graceful shutdown of VM...
Replacing VMDK with VDI...
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Clone hard disk created in format 'VDI'. UUID: 3ce3aa1f-3e79-41a3-952e-c26fcea961bf
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Resizing the disk...
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Boot and Re-partitioning...
Reboot and Resizing the partition...
Complete successfully
$ vagrant ssh -c 'df' -- -T
Filesystem           1K-blocks      Used Available Use% Mounted on
devtmpfs                506580         0    506580   0% /dev
tmpfs                   511944         0    511944   0% /run
cgroup                  511944         0    511944   0% /sys/fs/cgroup
/dev/sda1             75735868     53204  72022760   0% /mnt/sda1
overlay               75735868     53204  72022760   0% /etc
```

## Usage

```
$ resize.sh [name] [size]
```

- `name`:  Name of Vagrant virtual machine (a value of config.vm.define?=default)
- `size`: Size in MB which you want to resize to.  If omit, it will just convert a disk from VMDK to VDI for the future use.

**Note) You must execute it at the folder alongside Vagrantfile with the VM of `name`.**
