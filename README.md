# mux AUR package

This repository contains the AUR package files for `mux`.

## Build test (Docker)

```bash
./test-docker-build.sh
```

## Getting started

```bash
git remote add aur ssh://aur@aur.archlinux.org/mux.git
```

## Maintain and publish to AUR (`mux`)

Prerequisites:
- You have an AUR account.
- Your SSH public key is added to AUR.
- You can push to `aur@aur.archlinux.org:mux.git`.

### Publish an update from this repo

```bash
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO README.md Dockerfile test-docker-build.sh
git commit -m "mux: update to x.y.z"
git push aur main:master
```

Note: AUR only accepts pushes to `master`. If your local branch is `main`, use:

```bash
git push aur main:master
```

If you want plain `git push aur` to work from `main`, set:

```bash
git config branch.main.remote aur
git config branch.main.merge refs/heads/master
```

## Updating for a new upstream release

1. Bump `pkgver` in `PKGBUILD`.
2. Regenerate `.SRCINFO`:
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```
3. Commit and push.
