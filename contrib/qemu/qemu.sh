#!/bin/sh

pushd `dirname $0` > /dev/null
HERE=`pwd`
popd > /dev/null

cd "${HERE}"

if [ ! -f barge.qcow2 ];then
  cp ../../barge.qcow2 . 2>/dev/null \
    || curl -OL https://github.com/bargees/barge-packer/releases/download/v2.0.0/barge.qcow2
fi

qemu-system-x86_64 -nographic -machine pc \
  -name barge-qemu \
  -m 1024 \
  -device virtio-net,netdev=user.0 \
  -netdev user,id=user.0,hostfwd=tcp::2222-:22,hostfwd=tcp::2375-:2375 \
  -drive file=barge.qcow2,if=virtio
