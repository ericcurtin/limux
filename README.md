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

- For each sequent run of the environment, it's simply:

  ```
  sudo ./limux.sh
  ```

- It is possible to start a UI with XServer XSDL (optional), but make sure you have installed:

  ```
  dnf group install -y "Fedora Workstation"
  dnf install -y gnome-flashback dbus-x11
  ```

  in the chroot. And XServer XSDL Android Application started. then run:

  ```
  sudo ./limux.sh fedora:35 ui
  ```

![4c5c70a1-8b8f-471a-9296-0b1539ee661f](https://user-images.githubusercontent.com/1694275/148059048-5ecb2416-51fd-40d8-bf89-7b9e9e8c0a4a.png)

