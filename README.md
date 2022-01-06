# limux

Linux (fedora 35 default, centos stream 9 also available) chroot in an Android (work with standard GNU/Linux also)  environment

# To install and use

- rooted phone, this is device specific on how to complete. Many Android devices get wiped clean when you unlock the bootloader (such as my Moto G 5G Plus) or root the phone, so back up your data. It's a security feature. Technically this is optional, but the unrooted version does not perform as well.

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

  ```
  curl -LO https://raw.githubusercontent.com/ericcurtin/limux/main/limux.sh && chmod +x limux.sh && sudo ./limux.sh
  ```

- For each subsequent run of the environment, it's simply:

  ```
  sudo ./limux.sh
  ```

- It is possible to start a UI with XServer XSDL app, make sure you start XSDL app first (optional):

  ```
  sudo ./limux.sh fedora:35 ui
  ```

![Screenshot (4 Jan 2022 15_28_08)](https://user-images.githubusercontent.com/1694275/148082696-b2391cf1-cbc5-4be5-8851-fccfa6c6ebb3.png)
