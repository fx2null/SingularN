**Part 2: Hardware Disassembly & Flashing Guide**

This guide covers the physical disassembly of the ThinkPad T430 to access its internal flash chips, followed by the external flashing process using a hardware programmer.

## Preparation

### Bill of Materials (BOM)
Before we start, here is the BOM.

![](media/what-do-you-need.jpg)

## Table of Contents:
* [1. Disassembly](#1-disassembly) (Skip if your laptop is already disassembled.)
* [2. Flashing](#2-flashing) (Jump straight to flashing.)
* [3. How This Build Differs from Upstream Heads](#how-this-build-differs-from-upstream-heads)

## 1. Disassembly

#### 1. Turn the laptop over and unscrew the screws as shown in the photo.

![](media/1.jpg)

#### 2. Open the lid, unscrew the 2 screws holding the keyboard and the 1 screw holding the modem, carefully disconnect the antenna from the module, and remove it.

![](media/2.jpg)

#### 3. Turn the laptop back over, pry up the keyboard and slide it towards the screen. Be careful — there is a connector under the keyboard. Disconnect it and remove the keyboard.

![](media/3.jpg)

![](media/4.jpg)

#### 4. Unscrew the screws holding the palmrest. Now we need a guitar pick — pry up the palmrest and carefully open it, as shown in the photo.

![](media/5.jpg)

![](media/6.jpg)

![](media/7.jpg)

![](media/8.jpg)

#### 5. Pull it towards yourself. Be careful not to break off the part of the palmrest that goes under the screen. After lifting the freed palmrest, disconnect the touchpad connector and remove the palmrest.

![](media/9.jpg)

![](media/10.jpg)

#### 6. Now unscrew all the marked screws and remove the speakers, disconnect the display ribbon cable (1), and disconnect the network card. You can also remove the RAM.

![](media/11.jpg)

![](media/12.jpg)

#### 7. After that, disconnect the second display ribbon cable and the USB cover. Also free all the wires going into the display.

![](media/13.jpg)

#### 8. While holding the display, unscrew the 2 remaining screws and carefully remove it.

![](media/14.jpg)

#### 9. Now disconnect the power jack cable and the fan cable.

![](media/15.jpg)

#### 10. Remove the SSD/HDD and, by pressing the ExpressCard dummy slot, remove it from the laptop.

![](media/16.jpg)

#### 11. Turn the laptop over and, after unlocking, remove the optical drive.

![](media/17.jpg)

#### 12. Pulling the magnesium roll cage upwards from the left side, remove it from the plastic.

![](media/19.jpg)

#### 13. Turn the motherboard over and unscrew the screws as shown in the photo. Then, after turning it back over, unscrew the screws holding the cooling system from 4 to 1, little by little. Be careful not to crack the processor, then remove the cooler.

![](media/21.jpg)

![](media/20.jpg)

#### 14. Now we can finally remove the cage and access the BIOS chips: U49 (4MB), where the Intel ME is located, and the main U99 (8MB), where the BIOS is located.

![](media/23.jpg)

## 2. Flashing

#### Preparation

Before starting, we need to install `flashrom`, the utility used for reading, verifying, and writing flash chips.

#### Installing `flashrom`

**Fedora / RHEL:**
```bash
sudo dnf install flashrom
```

**Arch Linux / Artix / EndeavourOS / Manjaro:**
You can install it directly from the official repositories using `pacman`:
```bash
sudo pacman -S flashrom
```

Alternatively, you can use an AUR helper (such as yay or paru) to install it:
```bash
yay -S flashrom
```

**Debian/Ubuntu:**
```bash
sudo apt install flashrom
```

**Void Linux:**
```bash
sudo xbps-install -S flashrom
```

**Alpine:**
```bash
sudo apk add flashrom
```

#### Flash Chips Layout

**As discovered during disassembly, the T430 motherboard houses two separate SPI flash chips located near the magnesium cage boundary:**

- Top Chip (U49): 4MB (32Mbit), contains the Intel Management Engine (ME) firmware.
- Bottom Chip (U99): 8MB (64Mbit), contains the main BIOS/UEFI payload.

Together they form a single 12MB flash space.

#### CRITICAL WARNING:

Before making any modifications, you must take at least 2 independent read dumps of both chips and verify their MD5/SHA256 hashes. If the hashes do not match, do not proceed — it means your test clip connection is unstable.

#### Wiring Diagram (CH341A)

Connect your SOP8/SOIC8 test clip to the hardware programmer. Double-check the Pin 1 marker (usually indicated by a red wire on the ribbon cable and a dot on the chip).

![](media/ch341a.jpg)

![](media/ch341a-on-chip.jpg)

#### Reading the Current Firmware (8MB chip)

1. **Connect the clip to the 8MB (Bottom) chip.**

**Before reading the firmware, change the directory to `SingularN/Dumps`, which was created automatically during the build script.**

```bash

cd Dumps

```

2. **Run the following command to check whether the computer detects our chip:**

```bash

sudo flashrom -p ch341a_spi

```
**If you did everything correctly, the output should be:**

```bash
flashrom v1.6.0 on Linux 7.0.8-200.fc44.x86_64 (x86_64)
flashrom is free software, get the source code at https://flashrom.org
Found Macronix flash chip "MX25L6405" (8192 kB, SPI) on ch341a_spi.
Found Macronix flash chip "MX25L6405D" (8192 kB, SPI) on ch341a_spi.
Found Macronix flash chip "MX25L6406E/MX25L6408E" (8192 kB, SPI) on ch341a_spi.
Found Macronix flash chip "MX25L6436E/NX25L6445E/MX25L6465E" (8192 KB, SPI) on ch341a_spi.
Found Macronix flash chip "MX25L6473E" (8192 kB, SPI) on ch341a_spi.
Found Macronix flash chip "MX25L6473F" (8192 kB, SPI) on ch341a_spi.
Multiple flash chip definitions match the detected chip(s): "MX25L6405", "MX25L6405D", "NX25L6406E/MX25L6408E", "MX25L6436E/MX25L6445E/MX25 L6465E", "MX25L6473E", "MX25L6473F"

Please specify which chip definition to use with the -c <chipname> option.
```

**Note:** The exact chip model may vary depending on your laptop's manufacturing date. In my case, it was a **MX25L6406E/MX25L6408E**.

3. **After confirming that the computer detects our chip, we can create dumps 1 and 2:**

```bash

sudo flashrom -p ch341a_spi -c MX25L6406E/MX25L6408E -r 8MB-1-dump.bin

```

```bash

sudo flashrom -p ch341a_spi -c MX25L6406E/MX25L6408E -r 8MB-2-dump.bin

```

4. **Checking the checksums:**

```bash

sha256sum 8MB-1-dump.bin 8MB-2-dump.bin

```

**If the connection is good, they will be EXACTLY the same.**
(Mine and yours will differ because I am not flashing for the first time.)

```bash
d327997fcea1a1fd623859d4bd61570552d1177e0538e4d274b4fc3d46495bff 8MB-1-dump.bin
d327997fceala1fd623859d4bd61570552d1177e0538e4d274b4fc3d46495bff 8MB-2-dump.bin
```

**!!! If the hashes do not match, do not proceed — it means your test clip connection is unstable !!!**

Also, do not delete these dumps. If something goes wrong, they will be the only way to restore functionality.

#### Flashing (8MB chip)

**Before flashing the firmware, change the directory to `SingularN/SingularN-roms`, which was created automatically during the build script.**

```bash

cd ..
cd SingularN-roms

```

**Run the following command to flash it:**

```bash

sudo flashrom -p ch341a_spi -c MX25L6406E/MX25L6408E -w SingularN-T430-v3.0.0-BOTTOM-8MB.rom

```

**The output should be:**

```bash

flashrom v1.6.0 on Linux 7.0.8-200.fc44.x86_64 (x86_64)
flashrom is free software, get the source code at https://flashrom.org
Found Macronix flash chip "MX25L6406E/MX25L6408E" (8192 kB, SPI) on ch341a_spi.
Reading old flash chip contents... done.
Updating flash chip contents... Erase/write done from 0 to 7fffff
Verifying flash... VERIFIED.

```

**Once more: if it is NOT VERIFIED, check the connection and reflash!**

#### Reading the Current Firmware (4MB chip)

1. **Connect the clip to the 4MB (Top) chip.**

**Before reading the firmware, change the directory to `SingularN/Dumps`, which was created automatically during the build script.**

```bash

cd ..
cd Dumps

```

2. **Run the following command to check whether the computer detects our chip:**

```bash

sudo flashrom -p ch341a_spi

```
**If you did everything correctly, the output should be:**

```bash

flashrom v1.6.0 on Linux 7.0.8-200.fc44.x86_64 (x86_64)
flashrom is free software, get the source code at https://flashrom.org
Found Macronix flash chip "MX25L3205(A)" (4096 kB, SPI) on ch341a_spi.
Found Macronix flash chip "MX25L3205D/MX25L3208D" (4096 kB, SPI) on ch341a_spi. Found Macronix flash chip "MX25L3206E/MX25L3208E" (4096 kB, SPI) on ch341a_spi.
Found Macronix flash chip "MX25L3273F" (4096 kB, SPI) on ch341a_spi.
Found Macronix flash chip "MX25L3233F/MX25L3273E" (4096 kB, SPI) on ch341a_spi.
Multiple flash chip definitions match the detected chip(s): "MX25L3205(A)", "MX25L3205D/MX25L3208D", "MX25L3206E/MX25L3208E", "MX25L3273F", MX25L3233F/MX25L3273E" 

Please specify which chip definition to use with the -c <chipname> option.

```

**Note:** The exact chip model may vary depending on your laptop's manufacturing date. In my case, it was a **MX25L3205D/MX25L3208D**.

3. **After confirming that the computer detects our chip, we can create dumps 1 and 2:**

```bash

sudo flashrom -p ch341a_spi -c MX25L3205D/MX25L3208D -r 4MB-1-dump.bin

```

```bash

sudo flashrom -p ch341a_spi -c MX25L3205D/MX25L3208D -r 4MB-2-dump.bin

```

4. **Checking the checksums:**

```bash

sha256sum 4MB-1-dump.bin 4MB-2-dump.bin

```

**If the connection is good, they will be EXACTLY the same.**
(Mine and yours will differ because I am not flashing for the first time.)

```bash
431c55816d20b1bc2b8cea875daf72a35ee54fccc2a89e1066d8b59cf00c4fce 4MB-1-dump.bin
431c55816d20b1bc2b8cea875daf72a35ee54fccc2a89e1066d8b59cf00c4fce 4MB-2-dump.bin
```

**!!! If the hashes do not match, do not proceed — it means your test clip connection is unstable !!!**

Also, do not delete these dumps. If something goes wrong, they will be the only way to restore functionality.

#### Flashing (4MB chip)

**Before flashing the firmware, change the directory to `SingularN/SingularN-roms`, which was created automatically during the build script.**

```bash

cd ..
cd SingularN-roms

```

**Run the following command to flash it:**

```bash

sudo flashrom -p ch341a_spi -c MX25L3205D/MX25L32080 -w SingularN-T430-v3.0.0-TOP-4MB.rom

```

**The output should be:**

```bash

flashrom v1.6.0 on Linux 7.0.8-200.fc44.x86_64 (x86_64) flashrom is free software, get the source code at https://flashrom.org
Found Macronix flash chip "MX25L3205D/MX25L32080" (4096 kB, SPI) on ch341a_spi.
This flash part has status UNTESTED for operations: WP
The test status of this chip may have been updated in the latest development version of flashrom. If you are running the latest development version, please email a report to flashrom@flashrom.org if any of the above operations work correctly for you with this flash chip. Please include the flashrom log file for all operations you tested (see the man page for details), and mention which mainboard or programmer you tested in the subject line.
You can also try to follow the instructions here: https://www.flashrom.org/contrib_howtos/how_to_mark_chip_tested.html
Thanks for your help!
Reading old flash chip contents... done.
Updating flash chip contents... Erase/write done from 0 to 3fffff
Verifying flash... VERIFIED.
```

**Once more: if it is NOT VERIFIED, check the connection and reflash!**

## And that's it! Now you can assemble and test it! I hope this guide helped you, and thank you for using SingularN!

```ASCII ART

############################################################
#                                                          #
#    .d888           .d8888b.                    888 888   #
#   d88P"           d88P  Y88b                   888 888   #
#   888                    888                   888 888   #
#   888888 888  888      .d88P 88888b.  888  888 888 888   #
#   888    `Y8bd8P'  .od888P"  888 "88b 888  888 888 888   #
#   888      X88K    d88P"     888  888 888  888 888 888   #
#   888    .d8""8b. 888"       888  888 Y88b 888 888 888   #
#   888    888  888 888888888  888  888  "Y88888 888 888   #
#                                                          #
############################################################
#          Heads Hardened Firmware for T430                #
############################################################

```

## How This Build Differs from Upstream Heads

At the end of this guide, you will find a detailed comparison explaining exactly how this build differs from the upstream Heads project.

The changes are split across two config files: the Heads board config (`EOL_t430-hotp-maximized.config`) and the coreboot config (`coreboot-t430-maximized.config`). Both are patched automatically by `build.sh`.

### Heads Config Changes

**`CONFIG_BOOT_STATIC_IP=n`** — Static IP at boot is disabled. Heads does not bring up a network with a fixed address before the OS starts, which reduces the attack surface at the firmware stage.

**`CONFIG_TMP_NOT_PRESENT=n`** — Tells Heads that a TPM chip is present and should be used. Required for HOTP attestation via a hardware token.

**`CONFIG_BOOT_GUI_MENU=y`** — Enables the graphical boot menu instead of the text-based one. Uses fbwhiptail and cairo for rendering.

**`CONFIG_TPM_PCR_SIGNATURE=y`** — Enables signature verification through TPM PCR registers. On every boot, Heads compares the hashes of each boot stage against reference values, detecting any changes to the firmware.

**`CONFIG_HOTPKEY=y`** — Enables support for a physical HOTP token (Nitrokey, Librem Key, Token2). On every boot the token generates a one-time code based on a counter — Heads checks it and halts the boot process if the code does not match. This is protection against an evil maid attack: silently replacing the firmware becomes impossible.

**`CONFIG_BOOT_KERNEL_ADD`** — Sets additional kernel parameters: `iommu=on,igfx,verbose intel_iommu=on,igfx_off swiotlb=65536`. These enable IOMMU at the kernel level, exclude the integrated GPU from IOMMU (required for correct display initialization), and allocate a 256 MB software I/O TLB buffer for DMA-incapable devices.

### Coreboot Config Changes

**`CONFIG_MAINBOARD_USE_LIBGFXINIT=y`** — Uses libgfxinit instead of the proprietary VGA BIOS blob for graphics initialization. libgfxinit is an open implementation written in Ada and is one of the key Libreboot-inspired flags in this build.

**`CONFIG_GENERIC_LINEAR_FRAMEBUFFER=y` / `CONFIG_LINEAR_FRAMEBUFFER=y`** — Enable the linear framebuffer. After GPU initialization via libgfxinit, the Linux kernel gets direct access to video memory for rendering the Heads graphical interface.

**`CONFIG_DRAM_RESET_GATE_SKIP=y`** — Skips the DRAM reset gate mechanism. On Ivy Bridge (T430) this mechanism is implemented incorrectly and causes a hang on reboot. This flag is required for stable operation on this specific hardware.

**`CONFIG_IOMMU=y` / `CONFIG_INTEL_VTD=y`** — Enable hardware device isolation through IOMMU and Intel VT-d. Each device gets access only to its own memory region. Critically important for Qubes OS — provides physical isolation of USB, network, and other controllers at the hardware level.

**`CONFIG_LINEAR_FRAMEBUFFER_MAX_HEIGHT=1600` / `CONFIG_LINEAR_FRAMEBUFFER_MAX_WIDTH=2560`** — Set the maximum framebuffer resolution. Without these flags coreboot may cap the resolution below what the display panel supports. Taken from the Libreboot config for T430.

**`CONFIG_SECURITY_CLEAR_DRAM_ON_REGULAR_BOOT=y`** — Clears RAM on every boot. Protection against a cold boot attack — after shutdown no data from the previous session remains in memory that could be read by physically removing the RAM stick.

**`CONFIG_DECOMPRESS_OFAST=y`** — Uses maximum optimization when decompressing the ramstage from ROM. Speeds up firmware startup.

**`CONFIG_NO_STAGE_CACHE=y`** — Disables caching of boot stages in SPI flash. Every boot reads data directly from ROM, eliminating the cache as a potential attack vector.

**`CONFIG_RAMSTAGE_ADA=y`** — Includes the Ada runtime in the ramstage. Required for libgfxinit to work — without it, a build with open-source graphics initialization is not possible.
