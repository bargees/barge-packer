BOX_NAME := docker-root.box
ISO_NAME := docker-root.iso

PACKER  := packer
VAGRANT := vagrant

DOCKER_ROOT_VERSION := 0.10.0
KERNEL_VERSION      := 4.0.9
VBOX_VERSION        := 5.0.2

box: $(BOX_NAME)

iso: $(ISO_NAME)

vbox: iso/assets/sbin/mount.vboxsf \
	iso/assets/lib/modules/vboxguest.ko iso/assets/lib/modules/vboxsf.ko

$(BOX_NAME): $(ISO_NAME) box/template.json box/vagrantfile.tpl \
	box/vagrant_plugin_guest_busybox.rb box/mount_virtualbox_shared_folder.rb \
	box/assets/profile box/assets/init.sh
	cd box && \
		$(PACKER) build template.json

EXTERNAL_SOURCES := iso/linux-$(KERNEL_VERSION).tar.xz iso/vboxguest.iso \
	iso/bzImage iso/rootfs.tar.xz iso/kernel.config

$(ISO_NAME): iso/Dockerfile iso/assets/isolinux.cfg $(EXTERNAL_SOURCES)
	$(VAGRANT) suspend
	cd iso && \
		$(VAGRANT) up --no-provision && \
		$(VAGRANT) provision && \
		$(VAGRANT) suspend

iso/linux-$(KERNEL_VERSION).tar.xz:
	curl -L https://www.kernel.org/pub/linux/kernel/v4.x/linux-$(KERNEL_VERSION).tar.xz \
		-o $@

iso/vboxguest.iso:
	curl -L http://download.virtualbox.org/virtualbox/$(VBOX_VERSION)/VBoxGuestAdditions_$(VBOX_VERSION).iso -o $@

iso/bzImage iso/rootfs.tar.xz:
	curl -L https://github.com/ailispaw/docker-root/releases/download/v$(DOCKER_ROOT_VERSION)/$(@F) \
		-o $@

iso/kernel.config:
	curl -L https://raw.githubusercontent.com/ailispaw/docker-root/v$(DOCKER_ROOT_VERSION)/configs/$(@F) \
		-o $@

install: $(BOX_NAME)
	$(VAGRANT) box add -f docker-root $(BOX_NAME)

boot_test: install
	$(VAGRANT) destroy -f
	$(VAGRANT) up --no-provision

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
	@$(VAGRANT) ssh -c "cat /etc/os-release" -- -T
	@echo "-----> hostname"
	@$(VAGRANT) ssh -c "hostname" -- -T
	@echo "-----> route"
	@$(VAGRANT) ssh -c "route" -- -T
	$(VAGRANT) suspend

clean:
	cd iso && $(VAGRANT) destroy -f
	$(RM) -r iso/.vagrant
	$(VAGRANT) destroy -f
	$(RM) -r .vagrant
	$(RM) $(EXTERNAL_SOURCES)
	$(RM) $(BOX_NAME)
	$(RM) $(ISO_NAME)
	$(RM) -r box/packer_cache

.PHONY: box iso vbox install boot_test test clean
