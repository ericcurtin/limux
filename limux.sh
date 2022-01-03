#!/bin/sh

set -e

mount_dir="f35"
mkdir -p $mount_dir/proc $mount_dir/sys $mount_dir/dev/pts
if ! [ -f "Fedora-Container-Base-35-1.2.aarch64.tar.xz" ]; then
  curl -OL https://download.fedoraproject.org/pub/fedora/linux/releases/35/Container/aarch64/images/Fedora-Container-Base-35-1.2.aarch64.tar.xz
  cd $mount_dir
  tar -xOf ../Fedora-Container-Base-35-1.2.aarch64.tar.xz --wildcards --no-anchored 'layer.tar' | tar xf -
  echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > etc/resolv.conf
  echo -e "127.0.0.1 localhost" > etc/hosts
  cd - > /dev/null
fi

if ! command -v sudo > /dev/null; then
  export DEBIAN_FRONTEND='noninteractive'
  pkg update -y
  pkg upgrade -y
  pkg install -y tsu openssh
fi

umount_all() {
  sudo umount $mount_dir/dev/pts > /dev/null || true
  sudo umount $mount_dir/dev/ > /dev/null || true
  sudo umount $mount_dir/sys/ > /dev/null || true
  sudo umount $mount_dir/proc/ > /dev/null || true
}

umount_all

sudo mount -t proc proc $mount_dir/proc/
sudo mount -t sysfs sys $mount_dir/sys/
sudo mount -o bind /dev $mount_dir/dev/
sudo mount -o bind /dev $mount_dir/dev/pts

sudo LD_PRELOAD= chroot $mount_dir /bin/env -i HOME=/root TERM="$TERM" \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login

umount_all
