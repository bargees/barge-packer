BOX_NAME := docker-root.box
ISO_NAME := docker-root.iso
IMG_NAME := docker-root.qcow2

PACKER  := packer
VAGRANT := vagrant

DOCKER_ROOT_VERSION := 1.0.11
KERNEL_VERSION      := 4.1.12
VBOX_VERSION        := 5.0.8

box: $(BOX_NAME)

iso: $(ISO_NAME)

qemu: $(IMG_NAME)

vbox: iso/assets/sbin/mount.vboxsf \
	iso/assets/lib/modules/vboxguest.ko iso/assets/lib/modules/vboxsf.ko

$(BOX_NAME): $(ISO_NAME) box/template.json box/vagrantfile.tpl \
	box/vagrant_plugin_guest_busybox.rb box/mount_virtualbox_shared_folder.rb \
	box/assets/profile box/assets/init.sh
	cd box && \
		$(PACKER) build -only=virtualbox template.json

$(IMG_NAME): box/docker-root.iso box/docker-root.img box/template.json box/assets/profile
	cd box && \
		$(PACKER) build -only=qemu template.json
	qemu-img convert -c -f qcow2 -O qcow2 box/output-qemu/docker-root.qcow2 $(IMG_NAME)
	$(RM) -r box/output-qemu

EXTERNAL_SOURCES := iso/linux-$(KERNEL_VERSION).tar.xz iso/vboxguest.iso \
	iso/bzImage iso/rootfs.tar.xz iso/kernel.config iso/isolinux.cfg

$(ISO_NAME): iso/Dockerfile $(EXTERNAL_SOURCES)
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

iso/bzImage iso/rootfs.tar.xz box/docker-root.iso box/docker-root.img:
	curl -L https://github.com/ailispaw/docker-root/releases/download/v$(DOCKER_ROOT_VERSION)/$(@F) \
		-o $@

iso/kernel.config iso/isolinux.cfg:
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
	$(RM) box/docker-root.iso box/docker-root.img
	$(RM) $(BOX_NAME)
	$(RM) $(ISO_NAME)
	$(RM) $(IMG_NAME)
	$(RM) -r box/packer_cache
	$(RM) -r box/output-qemu

.PHONY: box qemu iso vbox install boot_test test clean
