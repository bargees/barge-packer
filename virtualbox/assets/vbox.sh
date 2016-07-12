
# Load the vboxsf module
if ! lsmod | grep -q vboxguest; then
  modprobe vboxguest 2>/dev/null || true
fi
if ! lsmod | grep -q vboxsf; then
  modprobe vboxsf 2>/dev/null || true
fi

# For timesync
/sbin/VBoxService --timesync-set-start --timesync-set-threshold 10000 --disable-automount
