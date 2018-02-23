BARGE_VERSION  := 2.8.0
KERNEL_VERSION := 4.14.24

ISO_NAME := barge-hyperv.iso

VAGRANT := vagrant

EXTERNAL_DEPENDENCIES := iso/linux-$(KERNEL_VERSION).tar.xz \
	iso/bzImage iso/rootfs.tar.xz iso/kernel.config iso/isolinux.cfg

iso: $(ISO_NAME)

$(ISO_NAME): iso/Dockerfile iso/S90hyperv $(EXTERNAL_DEPENDENCIES)
	cd iso && \
		$(VAGRANT) up --no-provision && \
		$(VAGRANT) provision && \
		$(VAGRANT) suspend

# EXTERNAL_DEPENDENCIES
iso/linux-$(KERNEL_VERSION).tar.xz:
	curl -L https://cdn.kernel.org/pub/linux/kernel/v4.x/$(@F) -o $@

iso/bzImage iso/rootfs.tar.xz:
	curl -L https://github.com/bargees/barge-os/releases/download/$(BARGE_VERSION)/$(@F) -o $@

iso/kernel.config iso/isolinux.cfg:
	curl -L https://raw.githubusercontent.com/bargees/barge-os/$(BARGE_VERSION)/configs/$(@F) -o $@

clean:
	-cd iso && $(VAGRANT) destroy -f
	$(RM) -r iso/.vagrant
	$(RM) $(EXTERNAL_DEPENDENCIES)
	$(RM) $(ISO_NAME)

.PHONY: iso clean
