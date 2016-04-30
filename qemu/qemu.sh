#!/bin/sh

pushd `dirname $0` > /dev/null
HERE=`pwd`
popd > /dev/null

cd "${HERE}"

qemu-system-x86_64 -nographic -machine pc \
  -name barge-qemu \
  -m 1024 \
  -device virtio-net,netdev=user.0 \
  -netdev user,id=user.0,hostfwd=tcp::2222-:22,hostfwd=tcp::2375-:2375 \
  -drive file=barge-test.qcow2,if=virtio
