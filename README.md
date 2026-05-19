# SingularN
SingularN is user-friendly build script for hardened Heads firmware on ThinkPad T430. Key feature is [Libreboot](https://libreboot.org)-inspired [coreboot](https://www.coreboot.org) flags for maximum security and openness. This project automates the compilation of firmware based on the [Heads](https://github.com/osresearch/heads) project.
## Installation Guide

This guide is split into two parts: **Software** and **Hardware**. 
1. **Software:** How to compile the custom firmware.
2. **Hardware:** How to flash and install it onto your device.

**(If you want, you can use finished ones from [Realeses](https://github.com/fx2null/SingularN/releases/))**

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

1. Open `build.sh` in a text editor.
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

#### Starting the script

```bash
chmod +x build.sh
# Giving the script execution permissions
./build.sh
#Starting the script
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
