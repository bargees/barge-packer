#!/bin/sh

DEV=/dev/sda
MNT=/mnt/sda1

(echo n; echo p; echo 2; echo; echo +1000M; echo w) | fdisk ${DEV}
(echo t; echo 82; echo w) | fdisk ${DEV}
until [ -b "${DEV}2" ]; do
  sleep 0.5
done
mkswap -L BARGE-SWAP ${DEV}2

(echo n; echo p; echo 1; echo; echo; echo w) | fdisk ${DEV}
until [ -b "${DEV}1" ]; do
  sleep 0.5
done
mkfs.ext4 -b 4096 -i 4096 -F -L BARGE-DATA ${DEV}1

mkdir -p ${MNT}
mount -t ext4 ${DEV}1 ${MNT}

mkdir -p ${MNT}/etc
mkdir -p ${MNT}/work/etc
mount -t overlay overlay -o lowerdir=/etc,upperdir=${MNT}/etc,workdir=${MNT}/work/etc /etc

mkdir -p /etc/default
wget -qO /etc/default/docker https://raw.githubusercontent.com/bargees/barge-packer/master/assets/profile
wget -qO /etc/init.d/init.sh https://raw.githubusercontent.com/bargees/barge-packer/master/assets/init.sh
chmod +x /etc/init.d/init.sh

sync; sync; sync
