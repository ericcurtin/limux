#!/bin/sh

set -e

if [ -z "$1" ]; then
  distro="fedora"
  rel="35"
else
  distro="$(echo "$1" | tr ":" "\n" | head -n1)"
  rel="$(echo "$1" | tr ":" "\n" | tail -n1)"
fi

if ! command -v sudo > /dev/null; then
  export DEBIAN_FRONTEND='noninteractive'
  pkg update -y
  pkg upgrade -y
  pkg install -y tsu openssh proot
fi

uname_m="$(uname -m)"
mount_dir_parent="$HOME/.limux/$distro/$rel/$uname_m"
mount_dir="$mount_dir_parent/fs"

mkdir -p $mount_dir_parent
if [ "$distro" = "fedora" ]; then
  fn="Fedora-Container-Base-$rel-1.2.$uname_m.tar.xz"
else
  fn="CentOS-Stream-Container-Base-$rel-20211222.0.$uname_m.tar.xz"
fi

if ! [ -f "$mount_dir_parent/$fn" ]; then
  cd $mount_dir_parent
  if [ "$distro" = "fedora" ]; then
    url="https://download.fedoraproject.org/pub/$distro/linux/releases/$rel/Container/$uname_m/images"
  else
    url="https://cloud.$distro.org/$distro/$rel-stream/$uname_m/images"
  fi

  echo "$url/$fn"
  curl -OL $url/$fn
  cd - > /dev/null
fi

if [ -z "$TMPDIR" ]; then
  TMPDIR="/tmp"
fi

if ! [ -d "$mount_dir" ]; then
  mkdir -p $mount_dir/proc $mount_dir/sys $mount_dir/dev/pts $mount_dir$TMPDIR
  cd $mount_dir
  tar -xOf ../$fn --wildcards --no-anchored 'layer.tar' | tar xf -
  echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > etc/resolv.conf
  echo -e "127.0.0.1 localhost" > etc/hosts
  cd - > /dev/null
fi

umount_all() {
  umount $mount_dir$TMPDIR > /dev/null 2>&1 || true
  umount $mount_dir/dev/pts > /dev/null 2>&1 || true
  umount $mount_dir/dev/ > /dev/null 2>&1 || true
  umount $mount_dir/proc/ > /dev/null 2>&1 || true
  umount $mount_dir/sys/ > /dev/null 2>&1|| true
}

if [ "$(id -u)" -eq 0 ]; then # rooted
  umount_all

  mount -t proc proc $mount_dir/proc/
  mount -t sysfs sys $mount_dir/sys/
  mount -o bind /dev $mount_dir/dev/
  mount -o bind /dev/pts $mount_dir/dev/pts
  mount -o bind $TMPDIR $mount_dir$TMPDIR

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

# Run the following for UI
# export DISPLAY=:0
# pkill dbus
# rm -f "/var/run/dbus/pid"
# dbus-daemon --system --fork
# dnf group install -y "Fedora Workstation"
# dnf install -y gnome-flashback
# /usr/libexec/gnome-flashback-metacity

