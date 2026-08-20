# Aurora bootc image

This repository follows the [Universal Blue image template](https://github.com/ublue-os/image-template) layout. `Containerfile` is the image entry point, `build_files/` contains build-time logic, and `system_files/` contains immutable image-owned configuration under `/usr`.

## Local build and switch

```bash
just build
just switch
# or: just build-and-switch
```

The default local image remains `localhost/laptop:latest`, matching the existing shell workflow. The base image is set in `image-template.env`; pin it to a digest when reproducibility is more important than automatically receiving Aurora updates.

## Runtime state and secrets

`/etc/restic/password.env` is intentionally machine-local: it is not copied into the image and must be created on the installed host. Backups target the mounted `X9 Pro` drive and skip cleanly when it is absent. Persistent user data remains under `/var/home` and is not image-owned.

## CI

The GitHub Actions workflow builds and publishes `ghcr.io/oandy-rgb/laptop` from `main`. To enable key-based signing, add the repository secret `SIGNING_SECRET` containing a Cosign private key; the workflow otherwise publishes an unsigned image.
