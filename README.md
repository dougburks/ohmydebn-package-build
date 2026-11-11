# ohmydebn-package-build

Prerequisites:
```
sudo apt install rubygems reprepro rclone squashfs-tools brotli jq openssl ffmpeg
sudo gem install fpm
```

`squashfs-tools` is needed by `build-package-ohmydebn-t3code.sh` to unpack AppImages.
`brotli` is needed by `build-package-ohmydebn-grok-build.sh` to unpack the Grok binary.
`ffmpeg` (with its VP9 encoder, libvpx) is needed by `build-package-ohmydebn-themes-omarchy-intros.sh` to re-encode the intro clips.
`build-package-ttfx.sh` builds from source with Debian's newer Rust (`rustc-web`, which replaces the default `rustc`), cross-compiling arm64: `sudo dpkg --add-architecture arm64 && sudo apt update && sudo apt install rustc-web cargo-web libstd-rust-web-dev:arm64 gcc-aarch64-linux-gnu`.
`build-package-ohmydebn-neovim-plugins.sh` runs on amd64 only and needs `gcc-aarch64-linux-gnu` (the arm64 parsers are cross-compiled; `build-package-ttfx.sh` needs it too) and `unshare` (util-linux) for its offline check.

## Layout

These scripts expect sibling directories next to this repo (normally in `~/git/`):

| Directory | Purpose |
|---|---|
| `ohmydebn-packages-staging/` | Built and downloaded `.deb` files (created automatically) |
| `ohmydebn-packages-candidates/` | Neovim plugin sets built for testing before they're published (created automatically; never uploaded) |
| `ohmydebn-packages-testing/` | reprepro testing repo |
| `ohmydebn-packages/` | reprepro stable repo |
| `ohmydebn/`, `omarchy/`, `gTile-OhMyDebn/`, ... | Package sources |

Paths are set in `common.sh` and derived from this repo's location, so the scripts can be run from any directory.
`STAGING_DIR`, `TESTING_REPO` and `STABLE_REPO` can be overridden from the environment.

The staging directory is not a scratch area: `upload-to-repo-stable.sh` includes every package from it, and some debs there (`mint-*`, `spice-vdagent`) are not produced by a script. It replaces each of those packages in stable as a whole, so it stops, before changing anything, if staging lacks an architecture stable has for a package, as it would after a build that failed partway.

## Workflow

1. Build a package, add it to the testing repo, and publish the testing repo: `~/git/ohmydebn-package-build/build-package-<name>.sh`
2. Promote everything in the staging directory to stable and publish it: `upload-to-repo-stable.sh`

Set `SKIP_UPLOAD=1` on either step to update the local repo without syncing to R2.
After a `SKIP_UPLOAD=1` build, `upload-to-repo-testing.sh` publishes the testing repo by hand.

The ohmydebn, ohmydebn-themes, ohmydebn-templates and ohmydebn-gtile builds package their checkout's working tree, so they stop if it has changes that aren't committed (ignored files don't count). Commit or remove them first.

Uploads prompt once for the rclone config password. To avoid the prompt, set `RCLONE_CONFIG_PASS` or `RCLONE_PASSWORD_COMMAND` in your shell.

## Backups of the repos' reprepro files

Each upload also copies that repo's `conf/` and `db/` (reprepro's configuration and package database, which the public buckets leave out) to the private R2 bucket `ohmydebn-reprepro-backup`, under `stable/` or `testing/` in a folder named for the upload's time (UTC). Without them, a lost repo could only be rebuilt by including every deb again by hand. To restore one, pick a folder with `rclone lsd r2:ohmydebn-reprepro-backup/stable` and copy it back into the repo with reprepro not running: `rclone copy r2:ohmydebn-reprepro-backup/stable/<folder> ~/git/ohmydebn-packages`. The published `dists/` and `pool/` come back from the public bucket the same way.

The repo signing key is never put in R2, this bucket included: anyone with access to the Cloudflare account could then sign packages. Keep its backup offline.

## Omarchy themes

`build-package-ohmydebn-themes-omarchy.sh` packages the themes from the `omarchy/` checkout. `build-package-ohmydebn-themes-omarchy-intros.sh` takes its clips from a pinned commit of its own (`OMARCHY_TAG` and `OMARCHY_COMMIT` there), but ships only those whose background the themes package has, which it reads from the same checkout. Both stop unless the checkout is at `OMARCHY_THEMES_TAG` in `common.sh` with nothing under `themes/` changed. To move to a new Omarchy release: `git -C ~/git/omarchy fetch --tags`, check out the new tag there, update `OMARCHY_THEMES_TAG` (and the intros script's pin, if its clips change), and rebuild both packages.

## Oh My Zsh

`build-package-ohmydebn-ohmyzsh.sh` packages Oh My Zsh from one pinned commit (`OMZ_COMMIT`, with its date in `OMZ_DATE`) into `/usr/share/oh-my-zsh`. Oh My Zsh publishes no releases, so to update it pick a newer commit from its `master` branch, try it, change both values, and rebuild.

## Tests

`tests/test-require-omarchy-checkout.sh` tests the Omarchy checkout check, and `tests/test-stage-checkout.sh` the uncommitted-changes check. Both use scratch git repositories and touch nothing else. `tests/test-upload-stable-arches.sh` tests `upload-to-repo-stable.sh`'s architecture check against a scratch repo, with uploading off. `tests/test-wget.sh` tests that a failed download names its URL, with a stand-in wget. `tests/test-reprepro-backup.sh` tests that an upload backs up `conf/` and `db/` to the private bucket and asks the rclone password once, with a stand-in rclone.
