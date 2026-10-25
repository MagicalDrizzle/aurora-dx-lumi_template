#!/bin/bash
# shellcheck disable=SC2310

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cd /tmp
cp -avf "/ctx/system_files"/. /
################----PERSONAL-START----################
# Boilerplate
# `:` == `true`
# `x || :` == `x || true` to ignore command failure
curl_gh() {
  command curl -sL \
    -H "Authorization: Bearer $(cat /run/secrets/GH_TOKEN)" \
    -H "Accept: application/vnd.github+json" \
    "$@"
}
create() {
    declare folder file
    if ! [[ -e ${folder} ]] ; then
        mkdir -p "${folder}" && touch "${folder}/${file}"
    fi
}
fedora_ver=$(rpm -E %fedora)    # 42, 43, 44...
grep -qF defaultyes=True /etc/dnf/dnf.conf || printf '%s\n' defaultyes=True | tee -a /etc/dnf/dnf.conf

# KDE customization
curl -sL -o /tmp/symlinks-italic.patch https://invent.kde.org/plasma/plasma-desktop/-/merge_requests/4117.patch
patch -p4 -i /tmp/symlinks-italic.patch -d /usr/share/plasma/plasmoids/org.kde.desktopcontainment
curl -sL -o /tmp/lockscreen-blur-toggle.patch https://invent.kde.org/plasma/plasma-desktop/-/merge_requests/4119.patch
patch -p2 -i /tmp/lockscreen-blur-toggle.patch -d /usr/share/plasma/shells/org.kde.plasma.desktop/
# End KDE customization

# RPM Fusion
dnf5 -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${fedora_ver}".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${fedora_ver}".noarch.rpm
dnf5 config-manager enable fedora-cisco-openh264
dnf5 config-manager enable rpmfusion-free rpmfusion-free-updates rpmfusion-nonfree rpmfusion-nonfree-updates
dnf5 -y install rpmfusion-\*-appstream-data
# Terra
dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release terra-release-extras terra-release-mesa
dnf5 config-manager enable terra terra-extras terra-mesa

# Hermes
kver="$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core | sort -V | tail -n1)"
dnf5 -y remove Sunshine
dnf5 -y install "$(curl_gh https://api.github.com/repos/MrOz59/Hermes/releases \
    | jq -r --arg ver "$fedora_ver" '[.[0].assets[].browser_download_url] |
    (map(select(contains(".fc" + $ver))).[0]) // (map(select(contains(".fc"))) | sort[-1])')"
# Hermes-KMS
git clone https://github.com/MrOz59/Hermes-KMS.git --single-branch \
    -b "$(curl_gh 'https://api.github.com/repos/MrOz59/Hermes-KMS/tags' | jq -r '.[0].name')" /tmp/hermes-kms
cd /tmp/hermes-kms
make modules KERNELRELEASE="${kver}" KDIR="/usr/lib/modules/${kver}/build" && \
make modules-install KERNELRELEASE="${kver}" DESTDIR=/
"/usr/lib/modules/${kver}/build/scripts/sign-file" sha512 /run/secrets/SB_KEY /run/secrets/SB_CERT \
    /usr/lib/modules/${kver}/extra/hermes-kms/hermes_kms.ko

### Gaming (Steam flatpak)
#dnf5 -y copr enable faugus/faugus-launcher
#dnf5 -y install faugus-launcher
#dnf5 config-manager disable copr:copr.fedorainfracloud.org:faugus:faugus-launcher
dnf5 -y install gamescope scopebuddy
# ###

# ProtonVPN (Terra)
dnf5 -y install python-proton-vpn-cli proton-vpn-qt-app

# CoolerControl
if dnf5 -y install coolercontrol coolercontrold; then
  systemctl enable coolercontrold
fi

# nohang
if dnf5 -y install --skip-unavailable nohang-nightly nohang-nightly-desktop; then
  systemctl mask systemd-oomd && systemctl enable nohang-desktop
fi

# RStudio
RS=$(curl_gh https://api.github.com/repos/rstudio/rstudio/tags | jq -r '.[0].name') && RS_VER=${RS:1}
dnf5 -y install https://download1.rstudio.org/electron/rhel9/x86_64/rstudio-"${RS_VER/+/-}"-x86_64.rpm

# Beyond Compare
dnf5 config-manager addrepo --from-repofile=https://www.scootersoftware.com/scootersoftware.repo
dnf5 config-manager disable scootersoftware
if dnf5 -y install bcompare --from-repo=scootersoftware; then
    sed -i 's/p1+wk/pn+wk/g' /usr/lib64/beyondcompare/BCompare
    git clone https://github.com/garfield-ts/BCompare_Keygen.git /tmp/bc_keygen
    python -m venv /tmp/bc_venv && source /tmp/bc_venv/bin/activate
    pip3 install base58==2.1.1 pycryptodome==3.24.0
    python /tmp/bc_keygen/keygen.py -u Mizuki -c innerworld -s 4462-6498 -n 4464 | tee /usr/lib64/beyondcompare/BC5Key.txt
    deactivate
fi

# VirtIO paravirtualization drivers for Windows
dnf5 config-manager addrepo --from-repofile=https://fedorapeople.org/groups/virt/virtio-win/virtio-win.repo
dnf5 config-manager disable virtio-win-stable virtio-win-latest virtio-win-source

# Syncthing Tray
dnf5 config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/home:mkittler/Fedora_"${fedora_ver}"/home:mkittler.repo
dnf5 -y install syncthingtray-qt6 syncthingplasmoid-qt6 syncthingfileitemaction-qt6 syncthingctl-qt6
dnf5 config-manager disable home_mkittler

# Adoptium Temurin JDK
dnf5 -y install adoptium-temurin-java-repository
dnf5 config-manager enable adoptium-temurin-java-repository
dnf5 -y install temurin-25-jdk

# Waydroid
dnf5 -y install waydroid
dnf5 -y copr enable cuteneko/waydroid-helper
dnf5 -y install --from-repo copr:copr.fedorainfracloud.org:cuteneko:waydroid-helper waydroid-helper

# Other softwares
systemctl enable podman.socket
dnf5 -y swap ddcutil terra-ddcutil
dnf5 -y install gsmartcontrol btrfs-heatmap btrfsmaintenance mmc-utils cmospwd \
                byebyebios efivar pesign sbsigntools smbios-utils coreboot-utils-all \
                usbview playerctl \
                gparted golly ucblogo vkmark below firejail hardinfo2 \
                lxqt-admin pcmanfm-qt zswap-cli qt5ct qt6ct accessibility-inspector \
                android-udev-rules chkconfig cpuinfo micro
                # pyside6-tools
                # cmake fakeroot mujs patch pigz rhash (included in brew)
# pesign doesn't have sysusers, fixed in F45
[ -f /usr/lib/sysusers.d/pesign.conf ] || printf '%s\n' "u pesign - 'Group for the pesign signing daemon' /run/pesign -" | tee /usr/lib/sysusers.d/pesign.conf
# cleanup
rm -rf /tmp/*
################----PERSONAL-END----################
