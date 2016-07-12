FROM ailispaw/ubuntu-essential:14.04

RUN apt-get -q update && \
    apt-get -q -y install --no-install-recommends bc build-essential \
      cpio kmod p7zip-full syslinux xorriso && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV SRCDIR /usr/src
WORKDIR ${SRCDIR}

ENV KERNEL_VERSION 4.4.15
COPY linux-${KERNEL_VERSION}.tar.xz ${SRCDIR}/
RUN tar xJf linux-${KERNEL_VERSION}.tar.xz

COPY kernel.config linux-${KERNEL_VERSION}/.config
RUN cd linux-${KERNEL_VERSION} && \
    make oldconfig && \
    make prepare && make scripts && \
    make headers_install INSTALL_HDR_PATH=${SRCDIR}

ENV VBOX_VERSION 5.1.0
RUN mkdir -p /vboxguest
COPY vboxguest.iso /vboxguest/
COPY patches /vboxguest/patches
RUN cd /vboxguest && \
    7z x vboxguest.iso -ir'!VBoxLinuxAdditions.run' && \
    rm -f vboxguest.iso && \
    \
    sh VBoxLinuxAdditions.run --noexec --target . && \
    mkdir -p amd64 && tar -C amd64 -xjf VBoxGuestAdditions-amd64.tar.bz2 && \
    rm -f VBoxGuestAdditions-amd64.tar.bz2 && \
    \
    rm -rf amd64/src/vboxguest-${VBOX_VERSION}/vboxvideo && \
    \
    for patch in /vboxguest/patches/*.patch; do \
      patch -p1 -d amd64/src/vboxguest-${VBOX_VERSION}/vboxsf < ${patch}; \
    done && \
    \
    KERN_DIR=${SRCDIR}/linux-${KERNEL_VERSION} KERN_INCL=${SRCDIR}/include \
      make -C amd64/src/vboxguest-${VBOX_VERSION}

RUN mkdir -p root
ADD rootfs.tar.xz ${SRCDIR}/root/

RUN cp /vboxguest/amd64/lib/VBoxGuestAdditions/mount.vboxsf root/sbin/ && \
    cp /vboxguest/amd64/sbin/VBoxService root/sbin/ && \
    cp /vboxguest/amd64/bin/VBoxControl root/bin/ && \
    cp /vboxguest/amd64/src/vboxguest-${VBOX_VERSION}/*.ko root/lib/modules/${KERNEL_VERSION}-barge/ && \
    depmod -a -b ${SRCDIR}/root ${KERNEL_VERSION}-barge

ENV ISO /iso

RUN mkdir -p ${ISO}/boot && \
    cd root && find | cpio -H newc -o | xz -9 -C crc32 -c > ${ISO}/boot/initrd

COPY bzImage ${ISO}/boot/

RUN mkdir -p ${ISO}/boot/isolinux && \
    cp /usr/lib/syslinux/isolinux.bin ${ISO}/boot/isolinux/ && \
    cp /usr/lib/syslinux/linux.c32 ${ISO}/boot/isolinux/ldlinux.c32

COPY isolinux.cfg ${ISO}/boot/isolinux/

# Copied from boot2docker, thanks.
RUN cd ${ISO} && \
    xorriso \
      -publisher "A.I. <ailis@paw.zone>" \
      -as mkisofs \
      -l -J -R -V "BARGE" \
      -no-emul-boot -boot-load-size 4 -boot-info-table \
      -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat \
      -isohybrid-mbr /usr/lib/syslinux/isohdpfx.bin \
      -no-pad -o /barge.iso $(pwd)

CMD ["cat", "/barge.iso"]
