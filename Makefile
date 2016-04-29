BOX_NAME := barge.box
ISO_NAME := barge.iso
IMG_NAME := barge.qcow2

PACKER  := packer
VAGRANT := vagrant

BARGE_VERSION  := 2.0.0
KERNEL_VERSION := 4.4.8
VBOX_VERSION   := 5.0.18

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

$(IMG_NAME): box/barge.iso box/barge.img box/template.json box/assets/profile
	cd box && \
		$(PACKER) build -only=qemu template.json
	qemu-img convert -c -f qcow2 -O qcow2 box/output-qemu/barge.qcow2 $(IMG_NAME)
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
	curl -L https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$(KERNEL_VERSION).tar.xz \
		-o $@

iso/vboxguest.iso:
	curl -L http://download.virtualbox.org/virtualbox/$(VBOX_VERSION)/VBoxGuestAdditions_$(VBOX_VERSION).iso -o $@

iso/bzImage iso/rootfs.tar.xz box/barge.iso box/barge.img:
	curl -L https://github.com/bargees/barge/releases/download/$(BARGE_VERSION)/$(@F) \
		-o $@

iso/kernel.config iso/isolinux.cfg:
	curl -L https://raw.githubusercontent.com/bargees/barge/$(BARGE_VERSION)/configs/$(@F) \
		-o $@

install: $(BOX_NAME)
	$(VAGRANT) box add -f barge $(BOX_NAME)

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
	$(RM) box/barge.iso box/barge.img
	$(RM) $(BOX_NAME)
	$(RM) $(ISO_NAME)
	$(RM) $(IMG_NAME)
	$(RM) -r box/packer_cache
	$(RM) -r box/output-qemu

.PHONY: box qemu iso vbox install boot_test test clean
