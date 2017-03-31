#!/bin/bash
set -e

GREEN="[38;5;2m"
RED="[38;5;1m"
CLEAR="[39m"

print_usage() {
  echo "Usage: $(basename $0) [name(config.vm.define?=default)]"
  if [ -n "$1" ] ; then
    echo
    echo -e "${RED}$1${CLEAR}"
  fi
}

# Check parameters
NAME="default"
if [ -n "$1" ] ; then
  NAME="$1"
fi

# Get UUID of VM
ID_FILE="./.vagrant/machines/${NAME}/virtualbox/id"
if [ ! -f "${ID_FILE}" ] ; then
  print_usage "Please execute in the folder alongside Vagrantfile with \"${NAME}\"." >&2
  exit 1
fi
UUID=$(cat ${ID_FILE})

# Get VMDK
VMDK_DISK_PATH=""
output=$(VBoxManage showvminfo ${UUID} --machinereadable | grep "SATA Controller-0-0")
pattern='^"SATA Controller-0-0"="(.+)"'
if [[ "${output}" =~ ${pattern} ]] ; then
  VMDK_DISK_PATH=${BASH_REMATCH[1]}
fi
if [ -z "${VMDK_DISK_PATH}" -o "${VMDK_DISK_PATH}" == "none" ] ; then
  print_usage "No HDD in the machine \"${NAME}\"." >&2
  exit 1
fi

# Set VDI
VDI_DISK_PATH="${VMDK_DISK_PATH%.*}.vdi"

if [ "${VMDK_DISK_PATH}" != "${VDI_DISK_PATH}" ] ; then
  echo -e "${GREEN}Stopping the VM...${CLEAR}"
  # Resume VM if it's suspended. Otherwise, the pertition may be broken.
  vagrant resume "${NAME}" > /dev/null 2>&1 || true
  vagrant halt "${NAME}"
  # Must wait to shutdown completely
  sleep 5

  echo -e "${GREEN}Replacing VMDK with VDI...${CLEAR}"
  # Convert VMDK to VDI
  VBoxManage clonehd "${VMDK_DISK_PATH}" "${VDI_DISK_PATH}" --format VDI --variant Standard

  # Detach VMDK
  VBoxManage storageattach "${UUID}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium none

  # Delete VMDK
  VBoxManage closemedium disk "${VMDK_DISK_PATH}" --delete

  # Attach VDI
  VBoxManage storageattach "${UUID}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${VDI_DISK_PATH}"
fi

echo -e "${GREEN}Boot and Cleanup the disk...${CLEAR}"
vagrant up "${NAME}" > /dev/null
vagrant ssh -c "sudo dd if=/dev/zero of=/mnt/data/EMPTY bs=1M; sudo rm -f /mnt/data/EMPTY" "${NAME}" > /dev/null 2>&1

echo -e "${GREEN}Stopping the VM...${CLEAR}"
vagrant halt "${NAME}"
# Must wait to shutdown completely
sleep 5

echo -e "${GREEN}Compact the disk...${CLEAR}"
VBoxManage modifyhd "${VDI_DISK_PATH}" --compact

vagrant up "${NAME}" > /dev/null
echo -e "${GREEN}Complete successfully${CLEAR}"
