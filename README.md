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

The staging directory is not a scratch area: `upload-to-repo-stable.sh` includes every package from it, and some debs there (`mint-*`, `spice-vdagent`) are not produced by a script.

## Workflow

1. Build a package, add it to the testing repo, and publish the testing repo: `~/git/ohmydebn-package-build/build-package-<name>.sh`
2. Promote everything in the staging directory to stable and publish it: `upload-to-repo-stable.sh`

Set `SKIP_UPLOAD=1` on either step to update the local repo without syncing to R2.
After a `SKIP_UPLOAD=1` build, `upload-to-repo-testing.sh` publishes the testing repo by hand.

The ohmydebn, ohmydebn-themes, ohmydebn-templates and ohmydebn-gtile builds package their checkout's working tree, so they stop if it has changes that aren't committed (ignored files don't count). Commit or remove them first.

Uploads prompt for the rclone config password. To avoid the prompt, set `RCLONE_CONFIG_PASS` or `RCLONE_PASSWORD_COMMAND` in your shell.

## Omarchy themes

`build-package-ohmydebn-themes-omarchy.sh` packages the themes from the `omarchy/` checkout. `build-package-ohmydebn-themes-omarchy-intros.sh` takes its clips from a pinned commit of its own (`OMARCHY_TAG` and `OMARCHY_COMMIT` there), but ships only those whose background the themes package has, which it reads from the same checkout. Both stop unless the checkout is at `OMARCHY_THEMES_TAG` in `common.sh` with nothing under `themes/` changed. To move to a new Omarchy release: `git -C ~/git/omarchy fetch --tags`, check out the new tag there, update `OMARCHY_THEMES_TAG` (and the intros script's pin, if its clips change), and rebuild both packages.

## Tests

`tests/test-require-omarchy-checkout.sh` tests the Omarchy checkout check, and `tests/test-stage-checkout.sh` the uncommitted-changes check. Both use scratch git repositories and touch nothing else.
