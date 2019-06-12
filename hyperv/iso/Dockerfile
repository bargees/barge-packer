FROM ailispaw/ubuntu-essential:18.04-nodoc

ENV SYSLINUX_SITE=https://mirrors.edge.kernel.org/ubuntu/pool/main/s/syslinux \
    SYSLINUX_VERSION=4.05+dfsg-6+deb8u1

RUN apt-get -q update && \
    apt-get -q -y install --no-install-recommends bc build-essential cpio syslinux xorriso \
      ca-certificates wget && \
    wget -q "${SYSLINUX_SITE}/syslinux-common_${SYSLINUX_VERSION}_all.deb" && \
    wget -q "${SYSLINUX_SITE}/syslinux_${SYSLINUX_VERSION}_amd64.deb" && \
    dpkg -i "syslinux-common_${SYSLINUX_VERSION}_all.deb" && \
    dpkg -i "syslinux_${SYSLINUX_VERSION}_amd64.deb" && \
    rm -f "syslinux-common_${SYSLINUX_VERSION}_all.deb" && \
    rm -f "syslinux_${SYSLINUX_VERSION}_amd64.deb" && \
    apt-get clean && rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*

ENV SRCDIR /usr/src
WORKDIR ${SRCDIR}

ENV KERNEL_VERSION 4.14.125
COPY linux-${KERNEL_VERSION}.tar.xz ${SRCDIR}/
RUN tar xJf linux-${KERNEL_VERSION}.tar.xz

COPY kernel.config linux-${KERNEL_VERSION}/.config
RUN cd linux-${KERNEL_VERSION} && \
    make oldconfig && \
    make prepare && make scripts && \
    make headers_install && \
    cd tools/hv && \
    make hv_kvp_daemon

RUN mkdir -p root
ADD rootfs.tar.xz ${SRCDIR}/root/

RUN cp ${SRCDIR}/linux-${KERNEL_VERSION}/tools/hv/hv_kvp_daemon root/usr/sbin/

COPY S90hyperv ${SRCDIR}/root/etc/init.d/

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
      -no-pad -o /barge-hyperv.iso $(pwd)

CMD ["cat", "/barge-hyperv.iso"]
