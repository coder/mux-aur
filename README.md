# mux AUR package

This repository contains the AUR package files for `mux`.

## Build test (Docker)

```bash
./test-docker-build.sh
```

## Maintain and publish to AUR (`mux`)

Prerequisites:
- You have an AUR account.
- Your SSH public key is added to AUR.
- You can push to `aur@aur.archlinux.org:mux.git`.

### This repo is already wired to AUR

`upstream` should point at `ssh://aur@aur.archlinux.org/mux.git`.

Verify:

```bash
git remote -v
```

You should see `upstream` mapped to the AUR repo.

### Publish an update from this repo

```bash
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO README.md Dockerfile test-docker-build.sh
git commit -m "mux: update to x.y.z"
git push upstream main:master
```

### If `upstream` is missing (one-time fix)

```bash
git remote add upstream ssh://aur@aur.archlinux.org/mux.git
git config branch.main.remote upstream
git config branch.main.merge refs/heads/master
```

## Updating for a new upstream release

1. Bump `pkgver` in `PKGBUILD`.
2. Regenerate `.SRCINFO`:
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```
3. Commit and push to `aur@aur.archlinux.org:mux.git`.
