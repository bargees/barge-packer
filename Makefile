TARGETS := virtualbox qemu
OBJECTS := barge.iso barge.box barge.qcow2

all: $(TARGETS)

virtualbox: barge.iso barge.box

qemu: barge.qcow2

barge.iso barge.box:
	$(MAKE) -C virtualbox $@
	cp virtualbox/$(@F) $@

barge.qcow2:
	$(MAKE) -C qemu $@
	cp qemu/$(@F) $@

clean:
	$(RM) $(OBJECTS)
	@for name in $(TARGETS); do \
		$(MAKE) -C $${name} clean; \
	done

.PHONY: all virtualbox qemu clean
