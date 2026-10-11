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
fedora_ver=$(rpm -E %fedora)    # 42, 43, 44...
echo defaultyes=True >> /etc/dnf/dnf.conf

# RPM Fusion
dnf5 -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${fedora_ver}".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${fedora_ver}".noarch.rpm
dnf5 config-manager enable fedora-cisco-openh264
dnf5 config-manager enable rpmfusion-free rpmfusion-free-updates rpmfusion-nonfree rpmfusion-nonfree-updates
dnf5 -y install rpmfusion-\*-appstream-data
# Terra
dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release terra-release-extras terra-release-mesa
dnf5 config-manager enable terra terra-extras terra-mesa

# Hermes
dnf5 -y install jq # in aurora already, just to be safe
dnf5 -y install "$(curl -s https://api.github.com/repos/MrOz59/Hermes/releases/latest \
    | jq -r --arg ver "$fedora_ver" '[.assets[].browser_download_url] |
    (map(select(contains(".fc" + $ver))).[0]) // (map(select(contains(".fc"))) | sort[-1])')"

git clone https://github.com/MrOz59/Hermes-KMS.git --single-branch \
    -b "$(curl -s 'https://api.github.com/repos/MrOz59/Hermes-KMS/tags' | jq -r '.[0].name')" /tmp/hermes-kms
cd /tmp/hermes-kms && make dkms-install

### Gaming
#dnf5 -y copr enable faugus/faugus-launcher
#dnf5 -y install faugus-launcher
#dnf5 config-manager disable copr:copr.fedorainfracloud.org:faugus:faugus-launcher
#dnf5 -y install steam mangohud gamescope scopebuddy protontricks
# ###

# ProtonVPN
dnf5 -y install https://repo.protonvpn.com/fedora-"${fedora_ver}"-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.4-1.noarch.rpm
dnf5 -y install proton-vpn-cli --from-repo=protonvpn-fedora-stable
dnf5 -y install proton-vpn-qt-app
dnf5 config-manager disable protonvpn-fedora-stable

# CoolerControl
if dnf5 -y install coolercontrol coolercontrold; then
  systemctl enable coolercontrold
fi

# nohang
if dnf5 -y install nohang-nightly nohang-nightly-desktop; then
  systemctl mask systemd-oomd && systemctl enable nohang-desktop
fi

# RStudio
RS_VER=$(curl -sL https://api.github.com/repos/rstudio/rstudio/tags | jq .[0].name)
RS_NAME=${RS_VER:2:-1}
dnf5 -y install https://download1.rstudio.org/electron/rhel9/x86_64/rstudio-"${RS_NAME/+/-}"-x86_64.rpm

# Beyond Compare
dnf5 config-manager addrepo --from-repofile=https://www.scootersoftware.com/scootersoftware.repo
dnf5 config-manager disable scootersoftware
if dnf5 -y install bcompare --from-repo=scootersoftware; then
    sed -i 's/p1+wk/pn+wk/g' /usr/lib64/beyondcompare/BCompare
    git clone https://github.com/garfield-ts/BCompare_Keygen.git /tmp/bc_keygen
    python -m venv /tmp/bc_venv && source /tmp/bc_venv/bin/activate
    pip3 install base58==2.1.1 pycryptodome==3.24.0
    python /tmp/bc_keygen/keygen.py -u Mizuki -c innerworld -s 4462-6498 -n 4464 > /usr/lib64/beyondcompare/BC5Key.txt
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

# Other softwares
systemctl enable podman.socket
dnf5 -y install gsmartcontrol btrfs-heatmap btrfsmaintenance mmc-utils cmospwd \
                byebyebios efivar pesign sbsigntools smbios-utils coreboot-utils-all \
                usbview playerctl pyside6-tools ddccontrol ddccontrol-gtk \
                gparted golly ucblogo vkmark below firejail hardinfo2 \
                lxqt-admin pcmanfm-qt zswap-cli qt5ct qt6ct accessibility-inspector \
                android-udev-rules chkconfig cpuinfo plocate
                # cmake fakeroot mujs patch pigz rhash (included in brew)

# KDE customization
systemctl enable systemd-sysext || true
systemd-sysext unmerge || true
create() {
    if ! [[ -e "${folder}" ]] ; then
        mkdir -p "${folder}"
        touch "${folder}/${file}"
    fi
}
################
origin=/usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ui/
folder=/etc/extensions/desktop-italics/${origin}
file=FolderItemDelegate.qml
create
perl -p0 -e 's/font.italic/\/\/ font.italic/' "${origin}/${file}" | tee "${folder}/${file}" >/dev/null

folder=/etc/extensions/desktop-italics/usr/lib/extension-release.d
file=extension-release.desktop-italics
create
echo ID=_any | tee "${folder}/${file}" >/dev/null
################
origin=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/
folder=/etc/extensions/lockscreen-unblur/${origin}
file=LockScreenUi.qml
create

perl -p0 -e 's/(hideClockWhenIdle\n +\})/$1 \*\// ; s/WallpaperFader/\/\* WallpaperFader/' "${origin}/${file}" | tee "${folder}/${file}" >/dev/null
folder=/etc/extensions/lockscreen-unblur/usr/lib/extension-release.d
file=extension-release.lockscreen-unblur
create
echo ID=_any | tee "${folder}/${file}" >/dev/null
################
systemd-sysext merge || true
# End KDE customization
################----PERSONAL-END----################
