# limux

Linux (fedora 35 default) chroot in an Android environment

# To install and use

- root phone (device specific instructions)

- Download and install open source app store F-Droid:

  https://f-droid.org/F-Droid.apk

- Install termux from F-Droid

- Configure sshd for termux (optional):

```
  pkg install -y openssh
  passwd # set password for current user
  sshd # starts on port 8022 rather than 22
```

- Open termux and run:

  `curl -LO https://raw.githubusercontent.com/ericcurtin/limux/main/limux.sh && chmod +x limux.sh && ./limux.sh`

