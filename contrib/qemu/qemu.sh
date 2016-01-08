#!/bin/sh

pushd `dirname $0` > /dev/null
HERE=`pwd`
popd > /dev/null

cd "${HERE}"

if [ ! -f docker-root.qcow2 ];then
  cp ../../docker-root.qcow2 . 2>/dev/null \
    || curl -OL https://github.com/ailispaw/docker-root-packer/releases/download/v1.2.7/docker-root.qcow2
fi

qemu-system-x86_64 -nographic -machine pc \
  -name docker-root-qemu \
  -m 1024 \
  -device virtio-net,netdev=user.0 \
  -netdev user,id=user.0,hostfwd=tcp::2222-:22,hostfwd=tcp::2375-:2375 \
  -drive file=docker-root.qcow2,if=virtio
