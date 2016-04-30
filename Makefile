TARGETS := virtualbox qemu

all: $(TARGETS)

virtualbox: output/barge.iso output/barge.box

qemu: output/barge.qcow2

output/barge.iso output/barge.box: output/% : virtualbox/% | output
	@install -CSv -m 0644 $< $@

virtualbox/barge.iso virtualbox/barge.box:
	$(MAKE) -C virtualbox $(@F)

output/barge.qcow2: output/% : qemu/% | output
	@install -CSv -m 0644 $< $@

qemu/barge.qcow2:
	$(MAKE) -C qemu $(@F)

output:
	mkdir -p $@

clean:
	$(RM) -r output
	@for name in $(TARGETS); do \
		$(MAKE) -C $${name} clean; \
	done

.PHONY: all virtualbox qemu clean
