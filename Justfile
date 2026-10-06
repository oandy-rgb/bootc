set dotenv-filename := "image-template.env"
set dotenv-load

image_name := env_var("IMAGE_NAME")
default_tag := env_var("DEFAULT_TAG")
base_image := env_var("BASE_IMAGE")

default:
    @just --list

build:
    podman build --pull=always --build-arg BASE_IMAGE="{{ base_image }}" -t "localhost/{{ image_name }}:{{ default_tag }}" .

switch:
    #!/usr/bin/env bash
    # 建置的映像在一般使用者的 Podman 儲存區，先匯入 root 儲存區給 bootc 使用。
    set -euo pipefail
    sudo -v
    podman image save --format oci-archive "localhost/{{ image_name }}:{{ default_tag }}" | sudo podman image load
    switch_output="$(sudo bootc switch --transport containers-storage "localhost/{{ image_name }}:{{ default_tag }}" 2>&1)"
    printf '%s\n' "$switch_output"

    # 映像來源同名時 switch 不會比較新 digest，改用 upgrade 排程新版本。
    if grep -Fq "Image specification is unchanged" <<<"$switch_output"; then
        sudo bootc upgrade
    fi

build-and-switch:
    just build
    just switch

nix-test-now:
    #!/usr/bin/env bash
    # 在目前開機中暫時套用映像內的 socket 設定，重開機後會自動消失。
    set -euo pipefail
    sudo -v
    sudo install -d -m 0755 /run/nix-daemon
    sudo install -D -m 0644 system_files/usr/lib/systemd/system/nix-daemon.socket.d/override.conf /run/systemd/system/nix-daemon.socket.d/override.conf
    sudo ln -sfn /run/nix-daemon/socket /nix/var/nix/daemon-socket/socket
    sudo systemctl daemon-reload
    sudo systemctl reset-failed nix-daemon.socket
    sudo systemctl start nix-daemon.socket
    nix store info --store daemon

check:
    just --fmt --check
    bash -n build_files/build.sh
