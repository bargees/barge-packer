#!/bin/sh

cat >> /etc/os-release << EOF
HOME_URL="https://atlas.hashicorp.com/ailispaw/boxes/docker-root"
SUPPORT_URL="https://github.com/ailispaw/docker-root"
BUG_REPORT_URL="https://github.com/ailispaw/docker-root/issues"
EOF

logger -s -p user.info -t "init.sh[$$]" "Configuring for Vagrant"
mkdir -p /home/docker/.ssh
chmod 0700 /home/docker/.ssh

if [ ! -f /home/docker/.ssh/authorized_keys ]; then
  cat <<KEY >/home/docker/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
KEY
  chmod 0600 /home/docker/.ssh/authorized_keys
fi
chown -R docker:docker /home/docker/.ssh

# Disable SSH Password Authentication
if ! grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
  echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
fi

# Load the vboxsf module
if ! lsmod | grep -q vboxguest; then
  modprobe vboxguest 2>/dev/null || true
fi
if ! lsmod | grep -q vboxsf; then
  modprobe vboxsf 2>/dev/null || true
fi
