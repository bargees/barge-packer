# Upgrade OS(ISO) in running VMs with Vagrant

## How to Upgrade OS(ISO) in Running VMs

```
# Make sure you have the latest version of the box.
$ vagrant box update --box ailispaw/docker-root --provider virtualbox
# If you've suspended the target VM, you need to resume it not to break the persistent disk.
$ vagrant resume
$ vagrant reload
```

You don't need to recreate a VM, because the VM will mount the new ISO in the new version of the box automatically during `vagrant reload`.  
But you need to update `~/.vagrant.d/data/machine-index/index` file manually.  
(You can leave it, but you will get warnings on `vagrant box remove`.)

### How to Check the Index file

#### Requierments

- [git](http://git-scm.com/) to get tools
- [jq](http://stedolan.github.io/jq/) to parse the index file

```
$ git clone https://github.com/ailispaw/docker-root-packer
$ cd docker-root-packer/contrib/vagrant
$ ./check.sh ailispaw/docker-root
Updating the box to make sure you have the latest one.
Checking for updates to 'ailispaw/docker-root'
Latest installed version: 1.0.0
Version constraints: > 1.0.0
Provider: virtualbox
Box 'ailispaw/docker-root' (v1.0.0) is running the latest version.
The latest version you have is 1.0.0.
No need to update.
```

## How to Rollback or Specify the particular version to boot

You can set `config.vm.box_version` as below and `vagrant reload`.

```ruby
Vagrant.configure(2) do |config|
  config.vm.box = "ailispaw/docker-root"

  config.vm.box_version = "0.11.0"
end
```

```
# If you've suspended the target VM, you need to resume it not to break the persistent disk.
$ vagrant resume
$ vagrant reload
```
