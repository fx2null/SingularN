#!/usr/bin/env bash
set -euo pipefail

BOARD_NAME="EOL_t430-hotp-maximized"
VERSION="v3.0.0"
NUM_CPUS=$(( $(nproc) - 1 ))

build_in_container() {
    podman run --rm \
        -v "$(pwd)":/home/user/SingularN:Z \
        -w /home/user/SingularN/heads \
        debian:stable bash -c "
            set -euo pipefail
            apt-get update
            apt-get install -y \
                git make gcc g++ gcc-multilib g++-multilib \
                libssl-dev libelf-dev libncurses-dev libncurses5-dev libncursesw5-dev \
                python3 python3-pip python3-dev python-is-python3 \
                bison flex gawk m4 \
                libgmp-dev libmpfr-dev libmpc-dev \
                wget curl ca-certificates \
                cmake ninja-build \
                autoconf automake libtool \
                gettext autopoint \
                imagemagick \
                innoextract \
                zip cpio rsync \
                gnat \
                libpng-dev libfreetype-dev libfontconfig-dev \
                libpixman-1-dev pkg-config \
                libpam0g-dev check \
                bc kmod \
                uuid-dev zlib1g-dev \
                device-tree-compiler \
                fakeroot patch unzip texinfo help2man \
                build-essential

            export CMAKE_POLICY_VERSION_MINIMUM=3.5

            if [ ! -f build/x86/coreboot-25.09/util/crossgcc/xgcc/bin/i386-elf-gcc ]; then
                make BOARD=${BOARD_NAME} crossgcc-i386 \
                    CPUS=${NUM_CPUS} \
                    GCC_OPTIONS='--enable-languages=c,ada' || true
            fi

            make BOARD=${BOARD_NAME} CPUS=${NUM_CPUS}
        "
}

if [ ! -d "heads" ]; then
    git clone https://github.com/osresearch/heads.git
fi

echo 'Changing bootsplash...'
rm ./heads/branding/Heads/bootsplash.jpg
cp ./bootsplash.jpg ./heads/branding/Heads/bootsplash.jpg

cd heads || exit 1

mkdir -p ./initrd/etc/
cat <<'LOGO' > ./initrd/etc/motd
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
LOGO

HEADS_CONF="./boards/${BOARD_NAME}/${BOARD_NAME}.config"
CB_CONF="./config/coreboot-t430-maximized.config"

heads_settings=(
    "CONFIG_BOOT_STATIC_IP=n"
    "CONFIG_TMP_NOT_PRESENT=n"
    "CONFIG_BOOT_GUI_MENU=y"
    "CONFIG_TPM_PCR_SIGNATURE=y"
    "CONFIG_HOTPKEY=y"
)

cb_settings=(
    "CONFIG_MAINBOARD_USE_LIBGFXINIT=y"
    "CONFIG_VGA_ROM_RUN=n"
    "CONFIG_GENERIC_LINEAR_FRAMEBUFFER=y"
    "CONFIG_LINEAR_FRAMEBUFFER=y"
    "CONFIG_DRAM_RESET_GATE_SKIP=y"
   #"CONFIG_INTEL_CHIPSET_LOCKDOWN=y"
    "CONFIG_IOMMU=y"
    "CONFIG_INTEL_VTD=y"
    "CONFIG_LINEAR_FRAMEBUFFER_MAX_HEIGHT=1600"
    "CONFIG_LINEAR_FRAMEBUFFER_MAX_WIDTH=2560"
    "CONFIG_SECURITY_CLEAR_DRAM_ON_REGULAR_BOOT=y"
    "CONFIG_DECOMPRESS_OFAST=y"
    "CONFIG_NO_STAGE_CACHE=y"
    "CONFIG_RAMSTAGE_ADA=y"
)

apply_heads_setting() {
    local key val entry
    key=$(echo "$1" | cut -d'=' -f1)
    val=$(echo "$1" | cut -d'=' -f2-)
    entry="export ${key}=${val}"
    local file=$2
    if grep -qE "^export ${key}=" "$file"; then
        sed -i "s|^export ${key}=.*|${entry}|" "$file"
    elif grep -qE "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${entry}|" "$file"
    else
        echo "${entry}" >> "$file"
    fi
}

apply_kconfig_setting() {
    local key val entry
    key=$(echo "$1" | cut -d'=' -f1)
    val=$(echo "$1" | cut -d'=' -f2-)
    entry="${key}=${val}"
    local file=$2
    if grep -qE "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${entry}|" "$file"
    elif grep -qE "^# ${key} is not set" "$file"; then
        sed -i "s|^# ${key} is not set|${entry}|" "$file"
    else
        echo "${entry}" >> "$file"
    fi
}

for s in "${heads_settings[@]}"; do apply_heads_setting "$s" "$HEADS_CONF"; done
for s in "${cb_settings[@]}";    do apply_kconfig_setting "$s" "$CB_CONF";  done

if grep -qE "^export CONFIG_BOOT_KERNEL_ADD=" "$HEADS_CONF"; then
    sed -i 's|^export CONFIG_BOOT_KERNEL_ADD=.*|export CONFIG_BOOT_KERNEL_ADD="iommu=on,igfx,verbose intel_iommu=on,igfx_off swiotlb=65536"|' "$HEADS_CONF"
else
    echo 'export CONFIG_BOOT_KERNEL_ADD="iommu=on,igfx,verbose intel_iommu=on,igfx_off swiotlb=65536"' >> "$HEADS_CONF"
fi

if grep -qE "^export CONFIG_BOOT_KERNEL_REMOVE=" "$HEADS_CONF"; then
    sed -i 's|^export CONFIG_BOOT_KERNEL_REMOVE=.*|export CONFIG_BOOT_KERNEL_REMOVE=""|' "$HEADS_CONF"
else
    echo 'export CONFIG_BOOT_KERNEL_REMOVE=""' >> "$HEADS_CONF"
fi

cd ..
build_in_container

ROM_PATH="./heads/build/x86/${BOARD_NAME}"

mv "${ROM_PATH}/heads-${BOARD_NAME}-"*"dirty.rom" \
   "${ROM_PATH}/SingularN-T430-HOTP-${VERSION}-FULL-12MB.rom" 2>/dev/null || true
mv "${ROM_PATH}/heads-${BOARD_NAME}-"*"-bottom.rom" \
   "${ROM_PATH}/SingularN-T430-HOTP-${VERSION}-BOTTOM-8MB.rom" 2>/dev/null || true
mv "${ROM_PATH}/heads-${BOARD_NAME}-"*"-top.rom" \
   "${ROM_PATH}/SingularN-T430-HOTP-${VERSION}-TOP-4MB.rom" 2>/dev/null || true

echo "Done: "
sha256sum "${ROM_PATH}/SingularN-T430-HOTP-${VERSION}-"*
mkdir -p SingularN-ROMS
mkdir -p Dumps
cp ${ROM_PATH}/SingularN* ./SingularN-ROMS/
