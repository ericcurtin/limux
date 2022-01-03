# limux

Linux (fedora 35 default) chroot in an Android environment

# To install and use

- rooted phone, this is device specific on how to complete. Many Android devices get wiped clean when you unlock the bootloader (such as my Moto G 5G Plus) or root the phone, so back up your data. It's a security feature. Technically this is optional, but unrooted version does not perform as well.

- Download and install open source app store F-Droid:

  https://f-droid.org/F-Droid.apk

- Install termux from F-Droid (Google Play version of termux is not recommended, it's drastically out of date)

- Configure sshd for termux (optional):

```
  pkg install -y openssh
  passwd # set password for current user
  sshd # starts on port 8022 rather than 22
```

- Open termux and run:

  `curl -LO https://raw.githubusercontent.com/ericcurtin/limux/main/limux.sh && chmod +x limux.sh && sudo ./limux.sh`

