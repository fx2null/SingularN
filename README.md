# SingularN
SingularN is user-friendly build script for hardened Heads firmware on ThinkPad T430. Key feature is [Libreboot](https://libreboot.org)-inspired [coreboot](https://www.coreboot.org) flags for maximum security and openness. This project automates the compilation of firmware based on the [Heads](https://github.com/osresearch/heads) project.

## Credits & Acknowledgments

This project uses a custom bootsplash logo based on the official Heads community artwork. 
Special thanks to the original creators and remix authors:

- **@ThePlexus** — for the original Heads "Qube" concept (combining coreboot's rabbit, LinuxBoot's penguin, and the Heads "H" logo).
- **@d-wid** — for the double-headed Janus logo design and creative remixes.
- **@ThrillerAtPlay** — for the Matrix binary background used in the theme composition.
- **@tlaurion** — for maintaining the original configuration assets and transformation guides.

The final bootsplash used in this repository is a personal modification of these combined community works.

## Installation Guide

This guide is split into two parts: **Software** and **Hardware**. 
1. **Software:** How to compile the custom firmware.
2. **Hardware:** How to flash and install it onto your device.

**(If you want, you can use finished ones from [Releases](https://github.com/fx2null/SingularN/releases/))**

**HOTP vs TOTP — What's the Difference?**

Both are one-time password standards, but they work differently. `TOTP` (Time-based) generates codes based on the current time — this is what most 2FA apps like Google Authenticator use. `HOTP` (HMAC-based) generates codes based on a counter that increments with each use. Heads uses `HOTP` specifically because it does not require a clock — the firmware has no reliable time source — and because the counter-based model ties the token directly to the number of boots, making any unexpected increment a red flag.

If your token does not support `HOTP` (for example, if it only does `TOTP`), do not use `HOTP` version. A misconfigured attestation setup is worse than none — it creates a false sense of security. Compatible hardware includes Nitrokey Pro/Storage, Librem Key, and Token2 HOTP-capable devices.

**A note on [GPG](https://gnupg.org/):** Regardless of which attestation method you use, having a GPG-capable token for signing /boot is strongly recommended and in practice nearly mandatory for a meaningful security setup. Without it, Heads can detect tampering but cannot verify the integrity of your kernel and initrd against a trusted key you physically hold. Supported tokens include Nitrokey Pro, Librem Key, and any OpenPGP-compatible smartcard.

**In short:**  if you have a compatible HOTP token, use `build-hotp.sh` — it gives you the full attestation chain. If you do not have one, use `build-totp.sh` instead, which displays a QR code on boot that you verify with any TOTP app on your phone. Either way, a GPG token for /boot signing remains highly recommended regardless of which script you choose.

At the end of this guide, you will find a detailed comparison explaining exactly how this build differs from the upstream Heads project.


---

### Part 1: Software Compilation

#### Prerequisites
To ensure cross-platform compatibility and keep your host system clean, the entire build process and all its dependencies are isolated inside a container. The only tool you need to install on your host machine is **Podman**. And for copying source code you need to install **Git**.

#### Installing Podman and Git

**Fedora / RHEL:**
```bash
sudo dnf install podman
sudo dnf install git
```

**Arch Linux / Artix / EndeavourOS / Manjaro:**
You can install Podman directly from the official repositories using `pacman`:
```bash
sudo pacman -S podman
sudo pacman -S git
```

Alternatively, you can use an AUR helper (such as yay or paru) to install it:
```bash
yay -S podman
yay -S git
```

**Debian/Ubuntu:**
```bash
sudo apt install podman
sudo apt install git
```

**Void Linux:**
```bash
sudo xbps-install -S podman
sudo xbps-install -S git
```

**Alpine:**
```bash
sudo apk add podman
sudo apk add git
```

#### Copying SingularN repo

To start the build process inside the isolated Podman container, you have to clone repo, and after that simply run the provided automation script:

```bash
git clone https://github.com/fx2null/SingularN.git
cd SingularN
```
#### Customizing the Bootsplash (Optional)

Inside the repository, you will find a default `bootsplash.jpg`. If you want to use your own custom boot image, simply overwrite it:

1. Move your preferred image into the project directory.
2. Delete or move the original file out.
3. Rename your new image to exactly `bootsplash.jpg`.

The script will automatically detect and embed your image during the compilation process.

#### Adjusting CPU Core Usage (Optional)

Please note that the compilation time can vary significantly depending on your hardware. By default, the build script automatically detects your CPU and uses **$N-1$ cores** (all available cores minus one). This prevents your host system from freezing or lagging during the intensive build process.

If you want to change this behavior (for example, to use all cores for maximum speed, or fewer cores to keep the system completely cool), open `build.sh` in a text editor and modify the core allocation variable at the top of the file.

1. Open `build-hotp.sh` or a `build-totp.sh` in a text editor.
2. Locate the **`NUM_CPUS`** variable at the top of the file:

   ```bash
   NUM_CPUS=$(( $(nproc) - 1 ))
   ```
3. 
    (1) Change it (for example I used 4, enter how many you want):
    ```bash
    NUM_CPUS=4
    ```
    (2) To use absolutely all available power (maximum speed, but the system might lag during build):

    ```bash
    NUM_CPUS=$(nproc)
    ```

#### Starting the script (It depends on which version you are using)

**For HOTP versioin:**

```bash

# Giving the script execution permissions
chmod +x build-hotp.sh

./build-hotp.sh
```

**For TOTP versioin:**

```bash

# Giving the script execution permissions
chmod +x build-totp.sh

./build-totp.sh
```

#### After script finished its work

Once the build process is complete, all 3 generated `.rom` files will be available in the `SingularN-ROMS` directory.

### Part 2: Hardware Flashing & Installation
Now that you have your compiled `.rom` files ready in the `SingularN-ROMS` directory, you need to flash them onto your ThinkPad T430 using an external programmer.
The complete step-by-step physical disassembly guide, chip pinouts (U49 and U99), and the exact `flashrom` commands are located in the dedicated hardware documentation file:
**[Read Part 2: Hardware Disassembly & Flashing](https://github.com/fx2null/SingularN/blob/main/hardware.md)**

## What All of This Actually Gives You

After going through all of this — the disassembly, the flashing, the custom build — what you end up with is a machine that boots entirely on open-source code, from the first instruction after power-on to the moment your OS takes over.

There is no proprietary VGA BIOS blob initializing your display. There is no Intel ME running its own closed firmware in the background with access to your memory and network. Graphics are initialized by libgfxinit — open Ada code that you can read, audit, and trust. Every boot stage is measured and verified against known-good values. A physical token in your hand is the final word on whether the machine is allowed to continue booting.

This is what firmware freedom looks like in practice: not just a philosophical position, but a concrete technical reality where every component of your boot chain is accounted for, auditable, and under your control.
