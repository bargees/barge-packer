# Resize a Persistent Disk in a Barge Vagrant box

It will convert a persistent disk from VMDK to VDI and resize it.

## How to Use

```
$ vagrant box add ailispaw/barge
$ vagrant init -m ailispaw/barge
$ vagrant up
$ vagrant ssh -c 'df' -- -T
Filesystem           1K-blocks      Used Available Use% Mounted on
tmpfs                   920952     48760    872192   5% /
devtmpfs                505844         0    505844   0% /dev
tmpfs                   511640         0    511640   0% /run
cgroup                  511640         0    511640   0% /sys/fs/cgroup
/dev/sda1             38255576     49268  36142440   0% /mnt/sda1
overlay               38255576     49268  36142440   0% /etc
$ curl -OL https://raw.githubusercontent.com/bargees/barge-packer/master/contrib/vagrant/resizedisk/resize.sh
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
tmpfs                   920952     48760    872192   5% /
devtmpfs                505844         0    505844   0% /dev
tmpfs                   511640         0    511640   0% /run
cgroup                  511640         0    511640   0% /sys/fs/cgroup
/dev/sda1             75735868     53284  72022680   0% /mnt/sda1
overlay               75735868     53284  72022680   0% /etc
```

## Usage

```
$ resize.sh [name] [size]
```

- `name`:  Name of Vagrant virtual machine (a value of config.vm.define?=default)
- `size`: Size in MB which you want to resize to.  If omit, it will just convert a disk from VMDK to VDI for the future use.

**Note) You must execute it at the folder alongside Vagrantfile with the VM of `name`.**
