```bash
just build
just switch
# or: just build-and-switch
```

能創一個aurora資料夾裡面放bootc,dotfiles,home-ops
`just build` 會用 `sudo podman build` 直接在 root 的 Podman 儲存區建置映像，`just switch` 再交給 bootc，中間不用匯出匯入。不要用 `sudo just ...`，需要權限時腳本會自己詢問。只改自己的設定、不想更新基底映像時，用 `just build-fast`（或 `just build-fast-and-switch`）。如果系統已經追蹤同名映像，腳本會自動改用 `bootc upgrade` 排程新 digest。預設映像名稱為 `localhost/laptop:latest`。基底映像設定在 `image-template.env`。

## Runtime state and secrets

`/etc/restic/password.env` is intentionally machine-local: it is not copied into the image and must be created on the installed host. Backups target the mounted `X9 Pro` drive and skip cleanly when it is absent. Persistent user data remains under `/var/home` and is not image-owned.

## Nix

映像使用 Fedora 提供的 `nix` 與 `nix-daemon`。由於 Aurora 的根檔案系統是唯讀的，開機時會建立 `/var/lib/nix`，再將它 bind mount 到 `/nix`。Nix store 會跨 bootc 更新與回滾保留；daemon socket 則放在適合 SELinux 的 `/run/nix-daemon`，並從 Nix 預設路徑連結過去。

切換映像並重新開機後可用以下指令檢查：

```bash
findmnt /nix
systemctl is-active nix-daemon.socket
nix store info
nix run nixpkgs#hello
```

如果要在重新建置與開機前先測試 socket 修正，可執行 `just nix-test-now`。它只會寫入 `/run` 中的臨時 systemd drop-in，不會重開機。


ujust jetbrains-toolbox
推薦用於jetbrains全家桶而不是flatpak

## k3s 與 Flux

映像內建 k3s，並透過 k3s 的自動部署安裝 Flux（做法沿用 `note/nixos` 的 `k3s-server.nix`）：

```text
/usr/share/k3s/manifests/flux.yaml        映像裡的來源（Flux Operator + FluxInstance 兩個 HelmChart）
        │ k3s.service 每次啟動前複製
        ▼
/var/lib/rancher/k3s/server/manifests/    k3s 自動套用這個資料夾
        ▼
Flux 同步 github.com/oandy-rgb/home-ops 的 clusters/oandy-laptop
```

升級 Flux Operator：改 `flux.yaml` 裡兩個 `version`，重建映像並重開機。不要刪除或改名 `flux.yaml`，HelmChart 消失時 k3s 會解除安裝 Flux。

GitHub token 與 age 私鑰不進映像。重灌後執行一次：

```bash
just flux-secrets   # 會詢問 GitHub token，age 私鑰讀 ~/.config/sops/age/keys.txt
```

從手動安裝的 Flux 遷移時，在切換到這版映像前先執行一次 `just flux-adopt`，讓 HelmChart 能接手既有的 FluxInstance。
