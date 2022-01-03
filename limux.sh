#!/bin/sh

set -e

if ! command -v sudo > /dev/null; then
  export DEBIAN_FRONTEND='noninteractive'
  pkg update -y
  pkg upgrade -y
  pkg install -y tsu openssh proot
fi

if [ "$(id -u)" -eq 0 ]; then # rooted
  mount_dir="f35-rooted"
else # unrooted
  mount_dir="f35-unrooted"
fi

if ! [ -f "Fedora-Container-Base-35-1.2.aarch64.tar.xz" ]; then
  curl -OL https://download.fedoraproject.org/pub/fedora/linux/releases/35/Container/aarch64/images/Fedora-Container-Base-35-1.2.aarch64.tar.xz
fi

if ! [ -d "$mount_dir" ]; then
  mkdir -p $mount_dir/proc $mount_dir/sys $mount_dir/dev/pts
  cd $mount_dir
  tar -xOf ../Fedora-Container-Base-35-1.2.aarch64.tar.xz --wildcards --no-anchored 'layer.tar' | tar xf -
  echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > etc/resolv.conf
  echo -e "127.0.0.1 localhost" > etc/hosts
  cd - > /dev/null
fi

umount_all() {
  umount $mount_dir/dev/pts > /dev/null 2>&1 || true
  umount $mount_dir/dev/ > /dev/null 2>&1 || true
  umount $mount_dir/sys/ > /dev/null 2>&1|| true
  umount $mount_dir/proc/ > /dev/null 2>&1 || true
}

if [ "$(id -u)" -eq 0 ]; then # rooted
  umount_all

  mount -t proc proc $mount_dir/proc/
  mount -t sysfs sys $mount_dir/sys/
  mount -o bind /dev $mount_dir/dev/
  mount -o bind /dev $mount_dir/dev/pts

  LD_PRELOAD= chroot $mount_dir /bin/env -i HOME=/root TERM="$TERM" \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login

  umount_all
else # unrooted
  echo "Warning: you are using the unrooted version of this script,"
  echo "         low performance, use sudo for maximum performance"

  LD_PRELOAD= proot --bind=/sys --bind=/proc --bind=/dev/pts --bind=/dev \
    --root-id --cwd=/ -L --sysvipc --link2symlink --kill-on-exit \
    --rootfs=$mount_dir /bin/env -i HOME=/root TERM="$TERM" \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login
fi

