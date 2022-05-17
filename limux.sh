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
  if command -v pkg > /dev/null; then
    export DEBIAN_FRONTEND='noninteractive'
    pkg update -y
    pkg upgrade -y
    pkg install -y tsu openssh proot
  fi
fi

uname_m="$(uname -m)"
if [ "$uname_m" != "aarch64" ] && [ "$uname_m" != "x86_64" ]; then
  echo "only aarch64 and x86_64 supported"
  exit 1
fi

mnt_dir_parent="$HOME/.limux/$distro/$rel/$uname_m"
mnt_dir="$mnt_dir_parent/fs"

mkdir -p $mnt_dir_parent
if [ "$distro" = "fedora" ]; then
  fn="Fedora-Container-Base-$rel-1.2.$uname_m.tar.xz"
elif [ "$distro" = "autosd" ]; then
  fn="auto-osbuild-cs9-minimal-regular-aarch64.tar.xz"
else
  fn="CentOS-Stream-Container-Base-$rel-20211222.0.$uname_m.tar.xz"
fi

if ! [ -f "$mnt_dir_parent/$fn" ]; then
  cd $mnt_dir_parent
  if [ "$distro" = "fedora" ]; then
    url="https://download.fedoraproject.org/pub/$distro/linux/releases/$rel/Container/$uname_m/images"
  elif [ "$distro" = "autosd" ]; then
    url="https://github.com/ericcurtin/limux/releases/download/0.0"
  else
    url="https://cloud.$distro.org/$distro/$rel-stream/$uname_m/images"
  fi

  curl -OL $url/$fn
  cd - > /dev/null
fi

if [ -z "$TMPDIR" ]; then
  TMPDIR="/tmp"
fi

if ! [ -d "$mnt_dir" ]; then
  mkdir -p $mnt_dir/proc $mnt_dir/sys $mnt_dir/dev/pts $mnt_dir$TMPDIR
  cd $mnt_dir
  tar -xOf ../$fn --wildcards --no-anchored 'layer.tar' | tar xf -
  echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > etc/resolv.conf
  echo -e "127.0.0.1 localhost" > etc/hosts
  cd - > /dev/null
fi

umount_all() {
  umount $mnt_dir$TMPDIR > /dev/null 2>&1 || true
  umount $mnt_dir/dev/pts > /dev/null 2>&1 || true
  umount $mnt_dir/dev/ > /dev/null 2>&1 || true
  umount $mnt_dir/proc/ > /dev/null 2>&1 || true
  umount $mnt_dir/sys/ > /dev/null 2>&1 || true
}

if [ "$(id -u)" -eq 0 ]; then # rooted
  LD_PRELOAD= chroot $mnt_dir /bin/env -i HOME=/root TERM="$TERM" \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login -c 'pidfile="/var/run/dbus/pid"
pid="`cat "$pidfile" > /dev/null 2>&1`"
kill -9 $pid > /dev/null 2>&1 || true
rm -f $pidfile'
  umount_all

  mkdir -p /dev/shm # chromium requires this
  mountpoint -q /dev/shm || mount -o rw,nosuid,nodev,mode=1777 -t tmpfs tmpfs /dev/shm
  mountpoint -q $mnt_dir/proc || mount -t proc proc $mnt_dir/proc
  mountpoint -q $mnt_dir/sys || mount -t sysfs sys $mnt_dir/sys
  mountpoint -q $mnt_dir/dev || mount -o bind /dev $mnt_dir/dev
  mountpoint -q $mnt_dir/dev/pts || mount -o bind /dev/pts $mnt_dir/dev/pts
  mountpoint -q $mnt_dir$TMPDIR || mount -o bind $TMPDIR $mnt_dir$TMPDIR

  if [ "$2" = "ui" ]; then
      if ! [ -f "$mnt_dir/usr/bin/xfce4-session" ]; then
        LD_PRELOAD= chroot $mnt_dir /bin/env -i HOME=/root TERM="$TERM" \
          PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login -c "dnf group install -y 'Xfce Desktop' --exclude kernel-core --skip-broken
dnf install -y dbus-x11"
      fi

      LD_PRELOAD= chroot $mnt_dir /bin/env -i HOME=/root TERM="$TERM" \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login -c 'export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1:4713 # from XServer XSDL
mkdir -p /run/dbus
dbus-daemon --system --fork
dbus-launch --exit-with-session xfce4-session > /dev/null 2>&1 &'
  elif [ "$2" = "ssh" ]; then
      if ! [ -f "$mnt_dir/usr/sbin/sshd" ]; then
        sshd_config="/etc/ssh/sshd_config"
        LD_PRELOAD= chroot $mnt_dir /bin/env -i HOME=/root TERM="$TERM" \
          PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login -c "dnf install -y openssh-server
sed -i -E 's/#?PasswordAuthentication .*/PasswordAuthentication yes/g' $sshd_config
sed -i -E 's/#?PermitRootLogin .*/PermitRootLogin yes/g' $sshd_config
ssh-keygen -A >/dev/null"
        cp -r ~/../.ssh $mnt_dir/root/
      fi

      LD_PRELOAD= chroot $mnt_dir /bin/env -i HOME=/root TERM="$TERM" \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login -c '/usr/sbin/sshd'
  fi

  LD_PRELOAD= chroot $mnt_dir /bin/env -i HOME=/root TERM="$TERM" \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login

  LD_PRELOAD= chroot $mnt_dir /bin/env -i HOME=/root TERM="$TERM" \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login -c 'pidfile="/var/run/dbus/pid"
pid="`cat "$pidfile" 2> /dev/null`"
kill $pid > /dev/null 2>&1 || true
pidfile="/run/sshd.pid"
pid="`cat "$pidfile" 2> /dev/null`"
kill $pid > /dev/null 2>&1 || true'

  umount_all
else # unrooted
  if [ "$2" = "ui" ]; then
    echo "Warning: UI not supported in the unrooted version of this script,"
    echo "         use sudo for UI. You can run without a UI unrooted, but"
    echo "         with lower performance"
    exit 0
  fi

  LD_PRELOAD= proot --bind=/sys --bind=/proc --bind=/dev/pts --bind=/dev \
    --bind=$TMPDIR --root-id --cwd=/ -L --sysvipc --link2symlink \
    --kill-on-exit --rootfs=$mnt_dir /bin/env -i HOME=/root TERM="$TERM" \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/bin /bin/bash --login
fi

