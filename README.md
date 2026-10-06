```bash
just build
just switch
# or: just build-and-switch
```

能創一個aurora資料夾裡面放bootc,dotfiles,home-ops
`just build` 會在一般使用者的 Podman 儲存區建置映像；`just switch` 會自動將映像匯入 root 儲存區，再交給 bootc。如果系統已經追蹤同名映像，腳本會自動改用 `bootc upgrade` 排程新 digest。預設映像名稱為 `localhost/laptop:latest`。基底映像設定在 `image-template.env`。

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
