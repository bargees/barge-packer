BARGE_VERSION  := 2.1.8

BOX_NAME := barge-veertu.box
VMZ_NAME := box/box.vmz

VAGRANT := vagrant

EXTERNAL_DEPENDENCIES := vmz/barge.iso box/vagrant_plugin_guest_busybox.rb box/mount_nfs.rb

box: $(BOX_NAME)

vmz: $(VMZ_NAME)

$(BOX_NAME): $(VMZ_NAME) box/metadata.json box/Vagrantfile \
	box/vagrant_plugin_guest_busybox.rb box/mount_nfs.rb
	cd box && tar zcf ../$@ $(^F)

$(VMZ_NAME): vmz/barge.iso vmz/hd0.img vmz/settings.plist
	cd vmz && tar zcf ../$@ $(^F)

# EXTERNAL_DEPENDENCIES
vmz/barge.iso:
	curl -L https://github.com/bargees/barge-os/releases/download/$(BARGE_VERSION)/$(@F) -o $@

box/vagrant_plugin_guest_busybox.rb box/mount_nfs.rb:
	cp ../virtualbox/box/$(@F) $@

# To test
install: $(BOX_NAME)
	$(VAGRANT) box add -f --provider veertu barge $(BOX_NAME)

boot_test: install
	$(VAGRANT) destroy -f
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
	@ssh -F .ssh_config barge-test 'bash -lc "cat /etc/os-release"'
	@echo "-----> hostname"
	@ssh -F .ssh_config barge-test 'bash -lc "hostname"'
	@echo "-----> route"
	@ssh -F .ssh_config barge-test 'bash -lc "route"'
	$(VAGRANT) suspend

clean:
	$(VAGRANT) destroy -f
	$(RM) -r .vagrant .ssh_config
	$(RM) $(EXTERNAL_DEPENDENCIES)
	$(RM) $(BOX_NAME)
	$(RM) $(VMZ_NAME)

.PHONY: box vmz install boot_test test clean
