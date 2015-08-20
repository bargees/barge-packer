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
(You can leave it, but you will get notifications on `vagrant box remove`.)

### How to Check the Index file

#### Requierments

- [git](http://git-scm.com/) to get tools
- [jq](http://stedolan.github.io/jq/) to parse the index file

```
$ git clone https://github.com/ailispaw/docker-root
$ cd rancheros-lite/contrib/upgrade
$ ./check.sh ailispaw/docker-root
Make sure I have the latest one.
Checking for updates to 'ailispaw/docker-root'
Latest installed version: 0.10.1
Version constraints: > 0.10.1
Provider: virtualbox
Box 'ailispaw/rancheros-lite' (v0.10.1) is running the latest version.
The latest version is 0.10.1.
No need to update.
```

## How to Rollback or Specify the particular version to boot

You can set `config.vm.box_version` as below and `vagrant reload`.

```ruby
Vagrant.configure(2) do |config|
  config.vm.box = "ailispaw/docker-root"

  config.vm.box_version = "0.9.9"
end
```

```
# If you've suspended the target VM, you need to resume it not to break the persistent disk.
$ vagrant resume
$ vagrant reload
```
