BARGE_VERSION := 2.7.3

BOX_NAME := barge-veertu.box
VMZ_NAME := box/box.vmz
HDD_NAME := vmz/barge-data.img

PACKER  := packer
VAGRANT := vagrant

EXTERNAL_DEPENDENCIES := vmz/barge.iso box/vagrant_plugin_guest_busybox.rb box/mount_nfs.rb \
	box/network_dhcp.erb

box: $(BOX_NAME)

vmz: $(VMZ_NAME)

hdd: $(HDD_NAME)

$(BOX_NAME): $(VMZ_NAME) box/metadata.json box/Vagrantfile \
	box/vagrant_plugin_guest_busybox.rb box/mount_nfs.rb box/prepare_nfs_settings.rb \
	box/network_dhcp.erb
	cd box && tar zcf ../$@ $(^F)

$(VMZ_NAME): $(HDD_NAME) vmz/barge.iso vmz/settings.plist
	cd vmz && tar zcf ../$@ $(^F)

$(HDD_NAME): vmz/barge.iso ../assets/profile ../assets/init.sh
	$(RM) -r hdd/output-qemu
	cd hdd && $(PACKER) build template.json
	@install -CSpv -m 0644 hdd/output-qemu/$(@F) $@

# EXTERNAL_DEPENDENCIES
vmz/barge.iso:
	curl -L https://github.com/bargees/barge-os/releases/download/$(BARGE_VERSION)/$(@F) -o $@

box/vagrant_plugin_guest_busybox.rb box/mount_nfs.rb box/network_dhcp.erb:
	cp ../virtualbox/box/$(@F) $@

# To test
install: $(BOX_NAME)
	$(VAGRANT) box add -f --provider veertu barge $(BOX_NAME)

boot_test: install
	-$(VAGRANT) destroy -f
	$(VAGRANT) up --provider veertu --no-provision
	@$(VAGRANT) ssh-config > .ssh_config

test: boot_test
	$(VAGRANT) provision
	@echo "-----> docker version"
	docker version
	@echo "-----> docker images"
	docker images
	@echo "-----> docker ps -a"
	docker ps -a
	@echo "-----> nc localhost 8080"
	@nc localhost 8080
	@echo "-----> /etc/os-release"
	@ssh -F .ssh_config barge-veertu-test 'bash -lc "cat /etc/os-release"'
	@echo "-----> hostname"
	@ssh -F .ssh_config barge-veertu-test 'bash -lc "hostname"'
	@echo "-----> route"
	@ssh -F .ssh_config barge-veertu-test 'bash -lc "route"'
	$(VAGRANT) suspend

clean:
	-$(VAGRANT) destroy -f
	$(RM) -r .vagrant .ssh_config
	$(RM) $(EXTERNAL_DEPENDENCIES)
	$(RM) $(BOX_NAME)
	$(RM) $(VMZ_NAME)
	$(RM) $(HDD_NAME)
	$(RM) -r hdd/packer_cache hdd/output-qemu

.PHONY: box vmz install boot_test test clean
