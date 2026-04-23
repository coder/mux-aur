# mux AUR package

Arch User Repository package for [mux](https://github.com/coder/mux).

Pushes to `main` on this repository are automatically published to
[`aur@aur.archlinux.org:mux.git`](https://aur.archlinux.org/packages/mux) by
the [`Publish` workflow](./.github/workflows/publish.yaml).

## Updating to a new upstream release

On Arch Linux (or inside the Docker image — see below):

```bash
./update.sh 0.17.0
git push origin main
```

`update.sh` bumps `pkgver`, resets `pkgrel` to `1`, refreshes `sha256sums`
(via `updpkgsums` from `pacman-contrib`), regenerates `.SRCINFO`, and creates
a commit. Pushing to `main` triggers the AUR publish workflow.

### From a non-Arch host

Run the update inside the repo's Arch container:

```bash
docker build -t mux-aur-build .
docker run --rm -it -v "$PWD:/work" -w /work mux-aur-build \
  bash -lc 'sudo chown -R builder /work && ./update.sh 0.17.0'
```

## Verifying the build locally

Before pushing a version bump, confirm the package still builds and installs:

```bash
./test-docker-build.sh
```

This runs `makepkg --syncdeps` inside an Arch container and installs the
resulting package to confirm `mux --help` works.

## Automated publishing

[`.github/workflows/publish.yaml`](./.github/workflows/publish.yaml) triggers
on every push to `main` that touches `PKGBUILD`, `.SRCINFO`, or the workflow
itself (and can also be run manually via *Run workflow*). It uses
[`KSXGitHub/github-actions-deploy-aur`](https://github.com/KSXGitHub/github-actions-deploy-aur)
to:

1. Check out the AUR `mux` repository.
2. Copy `PKGBUILD` from this repo.
3. Regenerate `.SRCINFO` inside an Arch container.
4. Commit and push to `ssh://aur@aur.archlinux.org/mux.git`.

### Required repository secrets

Configure these under **Settings → Secrets and variables → Actions**:

| Secret | Description |
| --- | --- |
| `AUR_USERNAME` | AUR account used in commit metadata. |
| `AUR_EMAIL` | Email used in commit metadata. |
| `AUR_SSH_PRIVATE_KEY` | Private SSH key authorized to push to the AUR `mux` repo. |

The matching public key must be registered on the `AUR_USERNAME` AUR account,
and that account must be a maintainer or co-maintainer of the `mux` package.

## Manual publishing (fallback)

If CI is unavailable, push directly to AUR:

```bash
git remote add aur ssh://aur@aur.archlinux.org/mux.git   # one-time setup
git push aur main:master
```

AUR only accepts pushes to its `master` branch, hence the `main:master`
refspec.

## Conventions

- `pkgver` tracks the upstream `mux` release (e.g. `0.16.0`).
- `pkgrel` is bumped when only the packaging changes (no new upstream
  release). `update.sh` resets it to `1` on every `pkgver` bump.
