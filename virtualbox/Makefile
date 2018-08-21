BARGE_VERSION  := 2.9.2
KERNEL_VERSION := 4.14.60
VBOX_VERSION   := 5.2.18

BOX_NAME := barge-vbox.box
ISO_NAME := barge-vbox.iso

PACKER  := packer
VAGRANT := vagrant

EXTERNAL_DEPENDENCIES := iso/linux-$(KERNEL_VERSION).tar.xz iso/vboxguest.iso \
	iso/bzImage iso/rootfs.tar.xz iso/kernel.config iso/isolinux.cfg

box: $(BOX_NAME)

iso: $(ISO_NAME)

$(BOX_NAME): $(ISO_NAME) box/template.json box/vagrantfile.tpl \
	box/vagrant_plugin_guest_busybox.rb box/mount_virtualbox_shared_folder.rb box/mount_nfs.rb \
	box/network_dhcp.erb \
	../assets/profile ../assets/init.sh
	cd box && \
		$(PACKER) build template.json

$(ISO_NAME): iso/Dockerfile $(EXTERNAL_DEPENDENCIES) $(shell find iso/patches -type f) \
	iso/S10vbox
	$(VAGRANT) suspend
	cd iso && \
		$(VAGRANT) up --no-provision && \
		$(VAGRANT) provision && \
		$(VAGRANT) suspend

# EXTERNAL_DEPENDENCIES
iso/linux-$(KERNEL_VERSION).tar.xz:
	curl -L https://cdn.kernel.org/pub/linux/kernel/v4.x/$(@F) -o $@

iso/vboxguest.iso:
	curl -L http://download.virtualbox.org/virtualbox/$(VBOX_VERSION)/VBoxGuestAdditions_$(VBOX_VERSION).iso -o $@

iso/bzImage iso/rootfs.tar.xz:
	curl -L https://github.com/bargees/barge-os/releases/download/$(BARGE_VERSION)/$(@F) -o $@

iso/kernel.config iso/isolinux.cfg:
	curl -L https://raw.githubusercontent.com/bargees/barge-os/$(BARGE_VERSION)/configs/$(@F) -o $@

# To test
install: $(BOX_NAME)
	$(VAGRANT) box add -f barge $(BOX_NAME)

boot_test: install
	-$(VAGRANT) destroy -f
	$(VAGRANT) up --no-provision
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
	-cd iso && $(VAGRANT) destroy -f
	$(RM) -r iso/.vagrant
	-$(VAGRANT) destroy -f
	$(RM) -r .vagrant .ssh_config
	$(RM) $(EXTERNAL_DEPENDENCIES)
	$(RM) $(BOX_NAME)
	$(RM) $(ISO_NAME)
	$(RM) -r box/packer_cache box/output-virtualbox

.PHONY: box iso install boot_test test clean
