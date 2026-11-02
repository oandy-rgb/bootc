#!/usr/bin/env bash
set -euo pipefail

SOPS_VERSION="v3.13.1"
K3S_VERSION="v1.31.5+k3s1"
GPOC_VERSION="3.2.0"

cp -av /ctx/system_files/. /

dnf install -y \
  --disablerepo="*" --enablerepo="fedora" --enablerepo="updates" \
  --setopt=zchunk=False --setopt=minrate=0 \
  nodejs python3 gcc git gh htop chezmoi age nix restic rclone \
  avr-binutils avr-gcc avr-libc
dnf install -y \
  --disablerepo="*" --enablerepo="fedora" --enablerepo="updates" \
  --setopt=zchunk=False --setopt=minrate=0 \
  "https://github.com/yuezk/GlobalProtect-openconnect/releases/download/v${GPOC_VERSION}/globalprotect-openconnect-${GPOC_VERSION}-1.x86_64.rpm"
dnf clean all

printf 'int main(void) { return 0; }\n' | \
  avr-gcc -mmcu=atmega328p -x c -o /tmp/avr-smoke.elf -
avr-size /tmp/avr-smoke.elf

curl -fL -o /usr/bin/sops \
  "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64"
chmod +x /usr/bin/sops
test "$(stat -c%s /usr/bin/sops)" -gt 1000000
sops --version

curl -fL -o /usr/bin/k3s \
  "https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s"
chmod +x /usr/bin/k3s
test "$(stat -c%s /usr/bin/k3s)" -gt 10000000
k3s --version

chmod +x /usr/bin/backup.sh
systemctl enable nix.mount nix-daemon.socket backup.timer
