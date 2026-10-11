#!/bin/bash
# shellcheck disable=SC2310

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
#dnf5 install -y tmux

################----PERSONAL-START----################

# Boilerplate
# `:` == `true`
# `x || :` == `x || true` to ignore command failure
fedora_ver=$(rpm -E %fedora)    # 42, 43, 44...
ignore_error() {
    if "$@"; then
        return 0
    else
        local rc=$?
        echo "DEBUG: command failed (${rc}): $*"
        return 0
    fi
}

# PowerShell, VSCode
# Finally brew has powershell :3
if ignore_error rpm --import https://packages.microsoft.com/keys/microsoft.asc; then
    #dnf5 config-manager addrepo --from-repofile=https://packages.microsoft.com/config/rhel/9/prod.repo --save-filename=microsoft-prod.repo
    #dnf5 install -y powershell
    # dnf5 install -y https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/powershell-7.5.4-1.rh.x86_64.rpm

    dnf5 config-manager addrepo --from-repofile=https://packages.microsoft.com/yumrepos/vscode/config.repo --save-filename=vscode.repo
    dnf5 install -y code --from-repo=vscode-yum
    dnf5 config-manager disable vscode-yum
fi

### Remove packages

###

# jotta-cli
tee /etc/yum.repos.d/jotta-cli.repo > /dev/null <<'EOF'
[jotta-cli]
name=Jottacloud CLI
enabled=0
baseurl=https://repo.jotta.cloud/redhat
gpgcheck=1
gpgkey=https://repo.jotta.cloud/public.gpg
EOF
dnf5 install -y jotta-cli --from-repo=jotta-cli
dnf5 config-manager disable jotta-cli

# ProtonVPN
dnf5 install -y https://repo.protonvpn.com/fedora-"${fedora_ver}"-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.4-1.noarch.rpm
ignore_error dnf5 install -y proton-vpn-gnome-desktop proton-vpn-cli --from-repo=protonvpn-fedora-stable || \
ignore_error dnf5 install -y proton-vpn-gnome-desktop proton-vpn-cli --from-repo=terra
dnf5 config-manager disable protonvpn-fedora-stable

# Mullvad VPN
# Awful CEO donated money to not very nice party...
# https://www.flamman.se/techprofil-ger-miljoner-till-orebropartiet/
#---# https://archive.is/FUhzn
# https://www.reddit.com/r/degoogle/comments/1ug25ag/for_those_thinking_of_switching_to_mullvad_from/
#---# https://archive.is/wip/cBqc6
#---# https://archive.is/wip/mh6nH
#dnf5 config-manager addrepo --from-repofile=https://repository.mullvad.net/rpm/stable/mullvad.repo --save-filename=mullvad-stable.repo
#dnf5 config-manager addrepo --from-repofile=https://repository.mullvad.net/rpm/beta/mullvad.repo --save-filename=mullvad-beta.repo
#dnf5 install -y mullvad-vpn --from-repo=mullvad-stable
#systemctl enable mullvad-early-boot-blocking
#systemctl enable mullvad-daemon

# CoolerControl (Terra is real outdated)
dnf5 copr enable -y codifryed/CoolerControl
dnf5 install -y liquidctl
if ignore_error dnf5 install -y coolercontrol coolercontrold --from-repo=copr:copr.fedorainfracloud.org:codifryed:CoolerControl; then
  systemctl enable coolercontrold
elif ignore_error dnf5 install -y coolercontrol coolercontrold --from-repo=terra; then
  systemctl enable coolercontrold
fi
dnf5 config-manager disable copr:copr.fedorainfracloud.org:codifryed:CoolerControl

# nohang
dnf5 install -y https://github.com/MagicalDrizzle/misc-binaries/raw/refs/heads/main/nohang-0.3.0-5.fc42.noarch.rpm \
https://github.com/MagicalDrizzle/misc-binaries/raw/refs/heads/main/nohang-desktop-0.3.0-5.fc42.noarch.rpm
systemctl enable nohang-desktop
systemctl mask systemd-oomd

# RStudio
RS_VER=$(curl -sL https://api.github.com/repos/rstudio/rstudio/tags | jq .[0].name)
RS_NAME=${RS_VER:2:-1}
dnf5 install -y https://download1.rstudio.org/electron/rhel9/x86_64/rstudio-"${RS_NAME/+/-}"-x86_64.rpm

# Sublime Text (now has flatpak!)
#dnf5 config-manager addrepo --from-repofile=https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
#dnf5 install -y sublime-text --from-repo=sublime-text
#repo-disable /etc/yum.repos.d/sublime-text.repo

# Portmaster
#PM_VER=$(curl -sL https://api.github.com/repos/safing/portmaster/releases/latest | jq .tag_name)
#dnf5 install -y https://updates.safing.io/latest/linux_amd64/packages/Portmaster-${PM_VER:2:-1}-1.x86_64.rpm

# Tailscale
# Repo file already included
#dnf5 install -y tailscale --from-repo=tailscale-stable
#dnf5 config-manager disable tailscale-stable

# Beyond Compare
dnf5 config-manager addrepo --from-repofile=https://www.scootersoftware.com/scootersoftware.repo
dnf5 install -y bcompare
dnf5 config-manager disable scootersoftware

# VirtIO paravirtualization drivers for Windows
dnf5 config-manager addrepo --from-repofile=https://fedorapeople.org/groups/virt/virtio-win/virtio-win.repo
# dnf5 install -y virtio-win        # you can get ISOs easily
dnf5 config-manager disable virtio-win-stable virtio-win-latest virtio-win-source

# Syncthing Tray
dnf5 config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/home:mkittler/Fedora_"${fedora_ver}"/home:mkittler.repo
dnf5 install -y syncthingtray-qt6 syncthingplasmoid-qt6 syncthingfileitemaction-qt6 syncthingctl-qt6
dnf5 config-manager disable home_mkittler

# Faugus Launcher
dnf5 -y copr enable faugus/faugus-launcher
dnf5 -y install faugus-launcher
dnf5 config-manager disable copr:copr.fedorainfracloud.org:faugus:faugus-launcher

# Adoptium Temurin JDK
dnf5 install -y adoptium-temurin-java-repository
dnf5 config-manager enable adoptium-temurin-java-repository
dnf5 install -y temurin-25-jdk

# Other softwares
echo defaultyes=True | tee -a /etc/dnf/dnf.conf
# Enable Terra
dnf5 config-manager enable terra
dnf5 config-manager enable terra-extras
# Enable RPM Fusion
dnf5 install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${fedora_ver}".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${fedora_ver}".noarch.rpm
dnf5 config-manager enable fedora-cisco-openh264
dnf5 config-manager enable rpmfusion-free rpmfusion-free-updates rpmfusion-nonfree rpmfusion-nonfree-updates
# Topgrade
dnf5 config-manager setopt terra.exclude='nerd-fonts scx-scheds steam python3-protobuf' terra-extras.exclude='nerd-fonts scx-scheds steam python3-protobuf'
dnf5 upgrade -y topgrade
# Wavemon
dnf5 copr enable -y ntulinux/wavemon
dnf5 install -y wavemon
dnf5 config-manager disable copr:copr.fedorainfracloud.org:ntulinux:wavemon

# kmscon
dnf5 copr enable -y jfalempe/kmscon
dnf5 install -y kmscon kmscon-freetype kmscon-gl kmscon-pango --from-repo=copr:copr.fedorainfracloud.org:jfalempe:kmscon
ln -sf /usr/lib/systemd/system/kmsconvt@.service /etc/systemd/system/autovt@.service
dnf5 config-manager disable copr:copr.fedorainfracloud.org:jfalempe:kmscon

# X11
ignore_error dnf5 nstall -y plasma-workspace-x11

# skip btdu, it causes trouble atm and i made a homebrew formula
# coreboot-utils-ectool conflicts with fw-ectool (Framework)
dnf5 remove -y fw-ectool
dnf5 install -y coreboot-utils-all

dnf5 install -y gparted gsmartcontrol btrfs-heatmap btrfsmaintenance memtest86+ flashrom gdisk mmc-utils \
                byebyebios efivar pesign sbsigntools smbios-utils cmospwd coreboot-utils-all \
                android-tools usbview podman-compose \
                playerctl python3-pyside6 pyside6-tools \
                kitty ksystemlog byobu golly ucblogo ddccontrol ddccontrol-gtk \
                rmlint cava vkmark iotop powertop below firejail earlyoom \
                hardinfo2 sysbench iperf3 \
                lxqt-admin pcmanfm-qt zswap-cli qt5ct qt6ct at-spi2-core accerciser \
                pandoc pandoc-pdf weasyprint cups-pdf \
                android-udev-rules chkconfig cpuinfo plocate
                # cmake fakeroot mujs patch pigz rhash (included in brew)
                # systemd-standalone-shutdown (incompatible with systemd)

# we have bazaar...?
#dnf5 install -y --setopt=install_weak_deps=False plasma-discover plasma-discover-flatpak plasma-discover-kns

# OpenZFS (Support is being removed... - ublue-os/aurora#1765)
# dnf5 install -y https://zfsonlinux.org/fedora/zfs-release-3-1"$(rpm --eval "%{dist}")".noarch.rpm
# #dnf5 install -y kernel-devel-"$(uname -r | awk -F'-' '{print $1}')"
# dnf5 install -y kernel-devel-matched
# dnf5 config-manager setopt zfs*.enabled=0
# dnf5 config-manager setopt zfs-latest.enabled=1
# dnf5 install -y zfs
# modprobe zfs
# # Protect ZFS from being removed by new kernel
# echo 'zfs' > /etc/dnf/protected.d/zfs.conf

# KDE customization
ignore_error systemctl enable systemd-sysext
ignore_error systemd-sysext unmerge
create() {
    if ! [[ -e "${folder}" ]] ; then
        mkdir -p "${folder}"
        touch "${folder}/${file}"
    fi
}
#############################################
origin=/usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ui/
folder=/etc/extensions/desktop-italics/${origin}
file=FolderItemDelegate.qml
create
perl -p0 -e 's/font.italic/\/\/ font.italic/' "${origin}/${file}" | tee "${folder}/${file}" >/dev/null

folder=/etc/extensions/desktop-italics/usr/lib/extension-release.d
file=extension-release.desktop-italics
create
echo ID=_any | tee "${folder}/${file}" >/dev/null
#############################################
origin=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/
folder=/etc/extensions/lockscreen-unblur/${origin}
file=LockScreenUi.qml
create

perl -p0 -e 's/(hideClockWhenIdle\n +\})/$1 \*\// ; s/WallpaperFader/\/\* WallpaperFader/' "${origin}/${file}" | tee "${folder}/${file}" >/dev/null
folder=/etc/extensions/lockscreen-unblur/usr/lib/extension-release.d
file=extension-release.lockscreen-unblur
create
echo ID=_any | tee "${folder}/${file}" >/dev/null
#############################################
ignore_error systemd-sysext merge
# End KDE customization

################----PERSONAL-END----################
# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

#systemctl enable podman.socket
