#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# The date this plugin set was tested. Bump it whenever lazy-lock.json in
# ../ohmydebn/config/nvim changes: install/config/nvim.sh refreshes each
# user's plugins when the package's lockfile changes.
VERSION="2026.9.26"
DESC="OhMyDebn's tested LazyVim plugins, parsers and tools for Neovim"
PACKAGE_NAME="ohmydebn-neovim-plugins"
URL="https://github.com/dougburks/ohmydebn"
INSTALL_DIR="/usr/lib/${PACKAGE_NAME}"
CONFIG_SRC="${GIT_ROOT}/ohmydebn/config/nvim"

# The Neovim and tree-sitter this set is built and tested with: whatever
# ohmydebn-neovim ships.
NVIM_VERSION=$(sed -n 's/^VERSION="\(.*\)"$/\1/p' "${BUILD_DIR}/build-package-ohmydebn-neovim.sh")
TREE_SITTER_VERSION=$(sed -n 's/^TREE_SITTER_VERSION="\(.*\)"$/\1/p' "${BUILD_DIR}/build-package-ohmydebn-neovim.sh")
NVIM_MINOR=${NVIM_VERSION%.*}
NVIM_NEXT_MINOR="${NVIM_MINOR%.*}.$((${NVIM_MINOR#*.} + 1))"

# Every plugin, parser and Mason tool a user's LazyVim needs, installed ahead
# of time so Neovim downloads nothing: nvim.sh copies this tree into each
# user's ~/.config/nvim and ~/.local/share/nvim, where lazy.nvim, Mason and
# nvim-treesitter manage it as usual (the approach Omarchy's omarchy-nvim
# takes). The plugins come from the lockfile committed in the ohmydebn repo;
# LAZY_UPDATE=1 instead updates them to their latest versions and writes the
# new lockfile back there, to test and commit.
#
# Plugins are Lua and the same on every architecture; parsers, blink.cmp's
# matcher and Mason's tools are native. This runs on amd64 only, so the arm64
# natives come from the same installers told they're on arm64: parsers are
# cross-compiled (gcc-aarch64-linux-gnu), and blink.cmp and Mason download
# their arm64 builds.
if [ "$(dpkg --print-architecture)" != "amd64" ]; then
  echo "This build runs on amd64 only" >&2
  exit 1
fi
command -v aarch64-linux-gnu-gcc >/dev/null || {
  echo "aarch64-linux-gnu-gcc not found: sudo apt install gcc-aarch64-linux-gnu" >&2
  exit 1
}

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}_*.deb
enter_work_dir

echo
echo "Downloading Neovim ${NVIM_VERSION} and tree-sitter ${TREE_SITTER_VERSION} to build with"
download_verified neovim/neovim "v${NVIM_VERSION}" nvim-linux-x86_64.tar.gz
download_verified tree-sitter/tree-sitter "v${TREE_SITTER_VERSION}" tree-sitter-linux-x64.gz
mkdir -p tools/bin
tar xzf nvim-linux-x86_64.tar.gz -C tools
ln -s ../nvim-linux-x86_64/bin/nvim tools/bin/nvim
gunzip -c tree-sitter-linux-x64.gz >tools/bin/tree-sitter
chmod 755 tools/bin/tree-sitter
export PATH="${WORK_DIR}/tools/bin:${PATH}"

# Runs nvim in one of the build homes: nvim-in <home> <nvim args>... A script
# rather than a function, since env and script(1) run it too.
cat >tools/bin/nvim-in <<'EOF'
#!/bin/bash
home="$1"
shift
HOME="${home}" XDG_CONFIG_HOME="${home}/config" XDG_DATA_HOME="${home}/data" \
  XDG_STATE_HOME="${home}/state" XDG_CACHE_HOME="${home}/cache" exec nvim "$@"
EOF
chmod 755 tools/bin/nvim-in

echo
echo "Assembling the OhMyDebn LazyVim config"
AMD64="${WORK_DIR}/home-amd64"
ARM64="${WORK_DIR}/home-arm64"
C="${AMD64}/config/nvim"
mkdir -p "${AMD64}"/{config,data,state,cache} "${ARM64}"/{config,data,state,cache}
# An explicit list: config/nvim also holds files nvim.sh used for older
# setups (the LazyVim v14, treesitter and gitsigns pins), which this tested
# set replaces.
for f in init.lua stylua.toml LICENSE lazyvim.json lazy-lock.json \
  lua/config/{lazy,options,keymaps,autocmds}.lua \
  lua/plugins/{all-themes,omarchy-theme-hotreload,snacks-animated-scrolling-off,ohmydebn-offline}.lua \
  plugin/after/transparency.lua; do
  install -D -m 644 "${CONFIG_SRC}/${f}" "${C}/${f}"
done

# The plugins the built-in themes (OhMyDebn's and Omarchy's) use: each
# theme's neovim.lua names its own, which the user's theme.lua loads when that
# theme is active. A build-only spec installs them all, so switching themes
# downloads nothing; it's removed before packaging, so users' plugin specs
# are exactly OhMyDebn's config plus their theme.lua, as before.
# Plus the template ohmydebn-theme-set-neovim fills in for themes without
# one (valid Lua as it stands: its placeholders sit inside strings).
THEME_GLOB="${GIT_ROOT}/ohmydebn/themes/*/neovim.lua
${GIT_ROOT}/omarchy/themes/*/neovim.lua
${CONFIG_SRC}/neovim.lua.tpl"
THEME_SPEC="lua/plugins/zz-build-theme-plugins.lua"
cat >theme-specs.lua <<'EOF'
-- Every plugin spec in the built-in themes' neovim.lua files (LazyVim's own
-- entry aside), with its name and dependencies, made lazy.
local specs = {}
local files = {}
for _, pattern in ipairs(vim.split(vim.env.THEME_GLOB, "\n")) do
  vim.list_extend(files, vim.fn.glob(pattern, false, true))
end
for _, file in ipairs(files) do
  local ok, theme = pcall(dofile, file)
  for _, spec in ipairs(ok and type(theme) == "table" and theme or {}) do
    if type(spec[1]) == "string" and spec[1] ~= "LazyVim/LazyVim" then
      table.insert(specs, { spec[1], name = spec.name, dependencies = spec.dependencies, lazy = true })
    end
  end
end
io.write("return " .. vim.inspect(specs) .. "\n")
EOF
THEME_GLOB="${THEME_GLOB}" nvim --clean --headless -c "luafile theme-specs.lua" -c qa >"${C}/${THEME_SPEC}" 2>&1
nvim --clean --headless -c "lua assert(#dofile('${C}/${THEME_SPEC}') > 0)" -c qa

echo
if [ "${LAZY_UPDATE:-0}" = "1" ]; then
  echo "Updating plugins to their latest versions (LAZY_UPDATE=1)"
  rm "${C}/lazy-lock.json"
  nvim-in "${AMD64}" --headless "+Lazy! sync" +qa >lazy.log 2>&1
  cp "${C}/lazy-lock.json" "${CONFIG_SRC}/lazy-lock.json"
else
  echo "Installing plugins at their lockfile versions"
  nvim-in "${AMD64}" --headless "+Lazy! restore" +qa >lazy.log 2>&1
  # A plugin the config names but the lockfile doesn't yet (a new theme's,
  # say) is installed at its latest version and added to the
  # lockfile; restore never changes the other entries.
  if ! cmp -s <(jq -S . "${C}/lazy-lock.json") <(jq -S . "${CONFIG_SRC}/lazy-lock.json"); then
    cp "${C}/lazy-lock.json" "${CONFIG_SRC}/lazy-lock.json"
    LOCKFILE_CHANGED=1
  fi
fi

# Every plugin a built-in theme's neovim.lua uses must now be in the set, or
# switching to that theme would download it.
cat >theme-plugins.lua <<'EOF'
local lock = vim.json.decode(table.concat(vim.fn.readfile(vim.env.LOCKFILE), "\n"))
local missing = {}
local function check(repo, name, file)
  if type(repo) == "string" and repo:find("/") and repo ~= "LazyVim/LazyVim" then
    name = name or repo:match("/([^/]+)$")
    if not lock[name] then
      table.insert(missing, repo .. " (" .. file .. ")")
    end
  end
end
local files = {}
for _, pattern in ipairs(vim.split(vim.env.THEME_GLOB, "\n")) do
  vim.list_extend(files, vim.fn.glob(pattern, false, true))
end
for _, file in ipairs(files) do
  local ok, specs = pcall(dofile, file)
  for _, spec in ipairs(ok and type(specs) == "table" and specs or {}) do
    check(spec[1], spec.name, file)
    for _, dep in ipairs(type(spec.dependencies) == "table" and spec.dependencies or {}) do
      check(type(dep) == "table" and dep[1] or dep, type(dep) == "table" and dep.name or nil, file)
    end
  end
end
io.write(table.concat(missing, "\n"))
EOF
THEME_MISSING=$(LOCKFILE="${C}/lazy-lock.json" THEME_GLOB="${THEME_GLOB}" \
  nvim --clean --headless -c "luafile theme-plugins.lua" -c qa 2>&1)
if [ -n "${THEME_MISSING}" ]; then
  echo "Theme plugins missing from the set:" >&2
  echo "${THEME_MISSING}" >&2
  exit 1
fi
# restore/sync run nvim-treesitter's build hook, which starts compiling
# parsers and is cut off when nvim quits; parsers are installed properly
# below, per architecture.
rm -rf "${AMD64}/data/nvim/site"

echo
echo "Trimming plugin git histories"
# Omarchy's slim_lazy_repos: each plugin keeps a git checkout, so :Lazy update
# and lazy's lockfile keep working, cut down to the checked-out commit.
# Tags at that commit stay: blink.cmp reads its version from
# `git describe --exact-match` and falls back to its slower Lua matcher
# without one. refs/remotes/origin/HEAD stays too: lazy.nvim finds the default
# branch of a plugin parked on a detached HEAD through it.
for dir in "${AMD64}"/data/nvim/lazy/*/; do
  [[ -d "${dir}/.git" ]] || continue
  head=$(git -C "${dir}" rev-parse HEAD)
  git -C "${dir}" sparse-checkout set --no-cone '/*' '!/test/' '!/tests/' '!/spec/'
  git -C "${dir}" for-each-ref --format='%(refname)' refs/remotes refs/tags |
    while IFS= read -r ref; do
      [[ ${ref} == refs/remotes/origin/HEAD ]] && continue
      [[ ${ref} == refs/tags/* && $(git -C "${dir}" rev-parse "${ref}^{commit}") == "${head}" ]] && continue
      git -C "${dir}" update-ref -d "${ref}"
    done
  rm -f "${dir}/.git/FETCH_HEAD" "${dir}/.git/ORIG_HEAD"
  {
    echo "${head}"
    git -C "${dir}" for-each-ref --format='%(objectname)' refs/heads
  } | sort -u >"${dir}/.git/shallow"
  git -C "${dir}" reflog expire --expire=all --all
  # lazy.nvim clones with --filter=blob:none, which marks the pack as a
  # promisor pack that gc won't repack or prune. The repo is shallow at its
  # tip now, so everything reachable is local: drop the promisor markers.
  git -C "${dir}" config --unset-all remote.origin.promisor || true
  git -C "${dir}" config --unset-all remote.origin.partialclonefilter || true
  rm -f "${dir}/.git/objects/pack/"*.promisor "${dir}/.git/objects/info/commit-graph"
  rm -rf "${dir}/.git/objects/info/commit-graphs"
  git -C "${dir}" -c gc.writeCommitGraph=false gc --prune=now --quiet
done
jq -r 'to_entries[] | "\(.key) \(.value.commit)"' "${C}/lazy-lock.json" | while read -r name commit; do
  if [ "$(git -C "${AMD64}/data/nvim/lazy/${name}" rev-parse HEAD)" != "${commit}" ]; then
    echo "${name} is not at its lockfile commit ${commit}" >&2
    exit 1
  fi
done

# The arm64 home starts from the same config and plugins.
cp -a "${AMD64}/config/nvim" "${ARM64}/config/nvim"
mkdir -p "${ARM64}/data/nvim"
cp -a "${AMD64}/data/nvim/lazy" "${ARM64}/data/nvim/lazy"

# The Mason packages LazyVim installs: its Mason list, plus the package of
# each language server it sets up through Mason (lua-language-server comes
# from there, through mason-lspconfig). mason-lspconfig maps servers to
# packages from Mason's registry, so until a fresh home has the registry this
# returns nil rather than a list missing the servers.
cat >mason-tools.lua <<'EOF'
if #require("mason-registry").get_all_package_names() == 0 then
  return nil
end
local tools = vim.deepcopy(LazyVim.opts("mason.nvim").ensure_installed or {})
local map = require("mason-lspconfig").get_mappings().lspconfig_to_package
for server, opts in pairs(LazyVim.opts("nvim-lspconfig").servers or {}) do
  local enabled = opts == true or (type(opts) == "table" and opts.enabled ~= false and opts.mason ~= false)
  if enabled and map[server] then
    table.insert(tools, map[server])
  end
end
return tools
EOF

# Installs every Mason package and waits, without blocking startup, until
# they and blink.cmp's matcher are in, then quits. No file is opened: in the arm64 home, Neovim's own Lua ftplugin would
# start treesitter with the arm64 parser, fail to load it, and stop at a
# "-- More --" prompt. Writes true/false to <state>/first-launch. With FIRST_LAUNCH_BLINK=0
# it leaves blink.cmp out (see the arm64 launch below).
cat >first-launch.lua <<EOF
local blink = vim.env.FIRST_LAUNCH_BLINK ~= "0"
if blink then
  require("lazy").load({ plugins = { "blink.cmp" } })
end
-- LazyVim's own requests (mason-lspconfig's for language servers) can come
-- before a fresh home has Mason's registry, and are then dropped; so each
-- tick installs whatever is missing once the registry knows it. (Not through
-- registry.refresh(): while LazyVim's own refresh runs, a second caller waits
-- on it forever.)
local function install_missing(registry, tools)
  for _, tool in ipairs(tools) do
    local found, pkg = pcall(registry.get_package, tool)
    if found and not pkg:is_installed() and not pkg:is_installing() then
      pkg:install()
    end
  end
end
local function done()
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return false
  end
  local tools = dofile("${WORK_DIR}/mason-tools.lua")
  if not tools then
    return false
  end
  install_missing(registry, tools)
  for _, tool in ipairs(tools) do
    if not registry.is_installed(tool) then
      return false
    end
  end
  local lib = vim.fn.stdpath("data") .. "/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.so"
  return not blink or vim.uv.fs_stat(lib) ~= nil
end
local started = vim.uv.now()
local timer = vim.uv.new_timer()
timer:start(5000, 2000, vim.schedule_wrap(function()
  local ok = done()
  if ok or vim.uv.now() - started > 600000 then
    timer:stop()
    -- Let in-flight post-install work (Mason's links) settle.
    vim.defer_fn(function()
      local f = assert(io.open(vim.fn.stdpath("state") .. "/first-launch", "w"))
      f:write(tostring(ok))
      f:close()
      vim.cmd("qa!")
    end, 3000)
  end
end))
EOF

# The arm64 launch: tree-sitter compiles with the cross compiler, minus the
# host's -m64 that tree-sitter adds and aarch64 gcc rejects. tree-sitter then
# loads the new parser to check it, which can't work for an arm64 library on
# this host, so a build that produced one counts as a success.
mkdir -p arm64-bin
cat >arm64-bin/cc <<'EOF'
#!/bin/bash
args=()
for a in "$@"; do [[ $a == -m64 ]] || args+=("$a"); done
exec aarch64-linux-gnu-gcc "${args[@]}"
EOF
cat >arm64-bin/tree-sitter <<EOF
#!/bin/bash
"${WORK_DIR}/tools/bin/tree-sitter" "\$@" && exit 0
[[ \$1 == build ]] && file -b parser.so 2>/dev/null | grep -q 'ARM aarch64' && exit 0
exit 1
EOF
chmod 755 arm64-bin/*

# Installs the native pieces into one home. Usage: install_native <arch> <home>
install_native() {
  local arch="$1" home="$2" data="$2/data/nvim" build_spec="$2/config/nvim/lua/plugins/zz-build.lua"
  local run=(nvim-in "${home}")
  local cmd=()
  if [ "${arch}" = "arm64" ]; then
    # blink.cmp is left out: after downloading its matcher it loads it, and
    # that failure (an arm64 library on this host) derails the rest of the
    # launch, Mason's installs included. It's downloaded below instead.
    run=(env PATH="${WORK_DIR}/arm64-bin:${PATH}" CC="${WORK_DIR}/arm64-bin/cc" FIRST_LAUNCH_BLINK=0 nvim-in "${home}")
    # Mason reads the architecture from uname once, when it loads.
    cmd=(--cmd 'lua local u = vim.uv.os_uname; vim.uv.os_uname = function() local r = u(); r.machine = "aarch64"; return r end')
  fi

  echo
  echo "Installing ${arch} parsers"
  "${run[@]}" --headless \
    -c "lua require('lazy').load({ plugins = { 'nvim-treesitter' } }); require('nvim-treesitter').install(LazyVim.opts('nvim-treesitter').ensure_installed):wait(600000)" \
    -c qa >"parsers-${arch}.log" 2>&1

  echo
  echo "Installing ${arch} Mason tools and blink.cmp matcher"
  # Build-only setting, loaded after ohmydebn-offline.lua: Mason fetches its
  # registry this once.
  echo 'return { { "mason-org/mason.nvim", opts = { registry_cache = { refresh = true } } } }' >"${build_spec}"
  rm -f "${home}/state/nvim/first-launch"
  # Neovim runs in a pty from script(1), since LazyVim only finishes starting
  # (VeryLazy) with a UI. Its stdin is /dev/null: timeout runs script in a
  # background process group, and a script reading the build's own terminal
  # would be stopped by it (SIGTTIN) and wait forever.
  timeout 700 script -qec "$(printf '%q ' "${run[@]}" "${cmd[@]}" -c "luafile ${WORK_DIR}/first-launch.lua")" /dev/null </dev/null >/dev/null 2>&1 || true
  rm "${build_spec}"
  if [ "$(cat "${home}/state/nvim/first-launch" 2>/dev/null)" != "true" ]; then
    echo "${arch}: Mason tools or blink.cmp's matcher did not install" >&2
    exit 1
  fi
  if [ "${arch}" = "arm64" ]; then
    # What blink.cmp's own download leaves: the release's library for the
    # target, its checksum file, and the version it was built for.
    local blink_tag release="${data}/lazy/blink.cmp/target/release"
    blink_tag=$(git -C "${data}/lazy/blink.cmp" describe --tags --exact-match)
    mkdir -p "${release}"
    (
      cd "${release}"
      download_verified saghen/blink.cmp "${blink_tag}" aarch64-unknown-linux-gnu.so
      download_verified saghen/blink.cmp "${blink_tag}" aarch64-unknown-linux-gnu.so.sha256
      mv aarch64-unknown-linux-gnu.so libblink_cmp_fuzzy.so
      mv aarch64-unknown-linux-gnu.so.sha256 libblink_cmp_fuzzy.so.sha256
      printf '%s' "${blink_tag}" >version
    )
  fi

  # Every native file is built for this architecture.
  local want
  want=$([ "${arch}" = "arm64" ] && echo "ARM aarch64" || echo "x86-64")
  # Every parser LazyVim wants (nvim-treesitter adds the ones they need, such
  # as dtd for xml).
  local missing
  missing=$(nvim-in "${home}" --headless -c "lua local have = LazyVim.treesitter.get_installed(true); for _, l in ipairs(LazyVim.opts('nvim-treesitter').ensure_installed) do if not have[l] then io.write(l, ' ') end end" -c qa)
  if [ -n "${missing}" ]; then
    echo "${arch}: parsers not installed: ${missing}" >&2
    exit 1
  fi
  find "${data}/site/parser" "${data}/lazy/blink.cmp/target" "${data}/mason/packages" -type f -print0 |
    xargs -0 file | grep ' ELF ' | grep -v "${want}" && {
    echo "${arch}: found native files for the wrong architecture (above)" >&2
    exit 1
  }

  # Paths must survive the copy into each user's home: absolute links
  # (treesitter's queries, Mason's bin) become relative, and Mason's
  # lua-language-server launcher finds its own directory.
  find "${data}" -type l | while read -r link; do
    target=$(readlink "${link}")
    if [[ ${target} == /* ]]; then ln -sfnr "${target}" "${link}"; fi
  done
  cat >"${data}/mason/packages/lua-language-server/lua-language-server" <<'EOF'
#!/usr/bin/env bash
exec "$(dirname "$(readlink -f "$0")")/libexec/bin/lua-language-server" "$@"
EOF
  chmod 755 "${data}/mason/packages/lua-language-server/lua-language-server"
  rm -rf "${data}/mason/packages/lua-language-server/libexec/log" "${data}/mason/staging"
  if grep -rlI --exclude-dir=.git "${home}" "${data}"; then
    echo "${arch}: files above still hold the build path" >&2
    exit 1
  fi
}

install_native amd64 "${AMD64}"
install_native arm64 "${ARM64}"
rm "${AMD64}/config/nvim/${THEME_SPEC}" "${ARM64}/config/nvim/${THEME_SPEC}"

echo
echo "Checking the amd64 set offline"
# A fresh home seeded from the build, with no network at all: every plugin
# is installed, and parsers, blink.cmp's matcher and Mason's tools all work.
SMOKE="${WORK_DIR}/home-smoke"
mkdir -p "${SMOKE}"/{config,data,state,cache}
cp -a "${AMD64}/config/nvim" "${SMOKE}/config/nvim"
cp -a "${AMD64}/data/nvim" "${SMOKE}/data/nvim"
cat >smoke.lua <<EOF
vim.defer_fn(function()
  local problems = {}
  for name, plugin in pairs(require("lazy.core.config").plugins) do
    if not plugin._.installed then
      table.insert(problems, "not installed: " .. name)
    end
  end
  if not LazyVim.treesitter.have("lua", "highlights") then
    table.insert(problems, "no lua parser")
  end
  if not pcall(require, "blink.cmp.fuzzy.rust") then
    table.insert(problems, "blink.cmp matcher does not load")
  end
  for _, tool in ipairs(dofile("${WORK_DIR}/mason-tools.lua") or { "(Mason has no registry)" }) do
    if not require("mason-registry").is_installed(tool) then
      table.insert(problems, "Mason tool missing: " .. tool)
    end
  end
  if #vim.lsp.get_clients({ name = "lua_ls" }) == 0 then
    table.insert(problems, "lua_ls did not start")
  end
  local f = assert(io.open(vim.fn.stdpath("state") .. "/smoke", "w"))
  f:write(#problems == 0 and "ok" or table.concat(problems, "\n"))
  f:close()
  vim.cmd("qa!")
end, 8000)
EOF
unshare -rn env HOME="${SMOKE}" XDG_CONFIG_HOME="${SMOKE}/config" XDG_DATA_HOME="${SMOKE}/data" \
  XDG_STATE_HOME="${SMOKE}/state" XDG_CACHE_HOME="${SMOKE}/cache" PATH="${PATH}" \
  script -qec "nvim ${SMOKE}/config/nvim/init.lua -c 'luafile ${WORK_DIR}/smoke.lua'" /dev/null </dev/null >/dev/null 2>&1 || true
if [ "$(cat "${SMOKE}/state/nvim/smoke" 2>/dev/null)" != "ok" ]; then
  echo "Offline check failed:" >&2
  cat "${SMOKE}/state/nvim/smoke" >&2 2>/dev/null || echo "(no result)" >&2
  exit 1
fi
if [ -s "${SMOKE}/state/nvim/mason.log" ]; then
  echo "Mason tried to reach the network offline:" >&2
  cat "${SMOKE}/state/nvim/mason.log" >&2
  exit 1
fi

for ARCHITECTURE in amd64 arm64; do
  HOME_DIR=$([ "${ARCHITECTURE}" = "arm64" ] && echo "${ARM64}" || echo "${AMD64}")
  mkdir -p pkgroot"${INSTALL_DIR}"
  cp -a "${HOME_DIR}/config/nvim" pkgroot"${INSTALL_DIR}/config"
  cp -a "${HOME_DIR}/data/nvim" pkgroot"${INSTALL_DIR}/data"
  chmod -R a+rX,go-w pkgroot

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    --maintainer "Doug Burks<doug.burks@example.com>" \
    -n "${PACKAGE_NAME}" \
    -v "${VERSION}" \
    --package "${STAGING_DIR}/" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "Apache-2.0 and others (each plugin's own)" \
    --depends "ohmydebn-neovim (>= ${NVIM_VERSION})" \
    --depends "ohmydebn-neovim (<< ${NVIM_NEXT_MINOR})" \
    --depends "git" \
    -C pkgroot \
    .

  echo
  echo "Removing ${ARCHITECTURE} temp files"
  rm -rf pkgroot
done

if [ "${LAZY_UPDATE:-0}" = "1" ]; then
  echo
  echo "Plugins updated: ${CONFIG_SRC}/lazy-lock.json has the new versions."
  echo "Test them, bump VERSION in this script, and commit the lockfile."
elif [ "${LOCKFILE_CHANGED:-0}" = "1" ]; then
  echo
  echo "New plugins were added to ${CONFIG_SRC}/lazy-lock.json."
  echo "Test them, bump VERSION in this script, and commit the lockfile."
fi

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
