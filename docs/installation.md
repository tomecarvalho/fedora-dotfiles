# Installation

## Internet: Ethernet or USB Tethering

Fedora Minimal does not contain WiFi drivers.

If possible, connect the computer via Ethernet. Otherwise, connect a mobile device capable of USB tethering and enable it.

## Installer

```sh
curl -fsSL https://raw.githubusercontent.com/tomecarvalho/fedora-dotfiles/main/install.sh | bash
```

This installs Git, clones the repository via HTTPS and starts the general installation.

After the general installation, you decide what optional groups it should install.

## Installation Groups

See [Installation Groups](./installation-groups.md).
