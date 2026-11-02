set dotenv-filename := "image-template.env"
set dotenv-load

image_name := env_var("IMAGE_NAME")
default_tag := env_var("DEFAULT_TAG")
base_image := env_var("BASE_IMAGE")

default:
    @just --list

# 直接建在 root 的 Podman 儲存區，bootc 可以直接讀取，不用再 save/load 整個映像。
build:
    sudo podman build --pull=newer --build-arg BASE_IMAGE="{{ base_image }}" -t "localhost/{{ image_name }}:{{ default_tag }}" .

# 不檢查基底映像更新，只重建自己的層。
build-fast:
    sudo podman build --pull=missing --build-arg BASE_IMAGE="{{ base_image }}" -t "localhost/{{ image_name }}:{{ default_tag }}" .

switch:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo -v
    switch_output="$(sudo bootc switch --transport containers-storage "localhost/{{ image_name }}:{{ default_tag }}" 2>&1)"
    printf '%s\n' "$switch_output"

    # 映像來源同名時 switch 不會比較新 digest，改用 upgrade 排程新版本。
    if grep -Fq "Image specification is unchanged" <<<"$switch_output"; then
        sudo bootc upgrade
    fi

build-and-switch:
    just build
    just switch

build-fast-and-switch:
    just build-fast
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

flux-secrets:
    #!/usr/bin/env bash
    # 重灌後執行一次：建立 Flux 需要、但不能放進映像的兩個 secret。
    set -euo pipefail
    read -rsp "GitHub token（需要 home-ops 讀取權限）: " token
    echo
    k3s kubectl create namespace flux-system --dry-run=client -o yaml | k3s kubectl apply -f -
    k3s kubectl -n flux-system create secret generic flux-system \
        --from-literal=username=git --from-literal=password="$token" \
        --dry-run=client -o yaml | k3s kubectl apply -f -
    k3s kubectl -n flux-system create secret generic sops-age \
        --from-file=age.agekey="$HOME/.config/sops/age/keys.txt" \
        --dry-run=client -o yaml | k3s kubectl apply -f -

flux-adopt:
    #!/usr/bin/env bash
    # 一次性遷移：讓 k3s 的 HelmChart 接手原本用 helm 和 kubectl 手動建立的 Flux。
    set -euo pipefail
    k3s kubectl -n flux-system label --overwrite fluxinstance flux app.kubernetes.io/managed-by=Helm
    k3s kubectl -n flux-system annotate --overwrite fluxinstance flux \
        meta.helm.sh/release-name=flux-instance meta.helm.sh/release-namespace=flux-system

check:
    just --fmt --check
    bash -n build_files/build.sh
