BARGE_VERSION := 2.3.6

IMG_NAME := output-qemu/barge.qcow2

EXTERNAL_DEPENDENCIES := barge.iso barge.img

$(IMG_NAME): barge.iso barge.img template.json ../assets/profile
	$(RM) -r output-qemu
	packer build template.json

$(EXTERNAL_DEPENDENCIES):
	curl -L https://github.com/bargees/barge-os/releases/download/$(BARGE_VERSION)/$(@F) -o $@

# To test
up test: qemu.sh barge-test.qcow2 
	./qemu.sh

barge-test.qcow2: $(IMG_NAME)
	cp $< $@

clean:
	$(RM) *.qcow2
	$(RM) -r packer_cache output-qemu
	$(RM) $(EXTERNAL_DEPENDENCIES)

.PHONY: up test clean
