#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
force=0
if [[ ${1:-} == --force ]]; then
  force=1
elif [[ $# -ne 0 ]]; then
  echo 'Usage: bash install.sh [--force]' >&2
  exit 2
fi

for file in config/init.lua config/CHEATSHEET.md vendor/mini.nvim/VERSION vendor/mini.nvim/LICENSE vendor/mini.nvim/lua/mini/pick.lua vendor/mini.nvim/lua/mini/extra.lua vendor/mini.nvim/lua/mini/diff.lua; do
  [[ -f "$repo_dir/$file" ]] || { echo "Missing $file; use a complete checkout" >&2; exit 1; }
done
if [[ $(uname -s) != Linux ]]; then
  echo "This setup is for Linux; this host is $(uname -s)" >&2
  exit 1
fi

mini_version=$(cat "$repo_dir/vendor/mini.nvim/VERSION")

version_at_least() {
  local have=$1 need=$2 h1 h2 h3 n1 n2 n3
  [[ $have =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1
  h1=${BASH_REMATCH[1]} h2=${BASH_REMATCH[2]} h3=${BASH_REMATCH[3]}
  [[ $need =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1
  n1=${BASH_REMATCH[1]} n2=${BASH_REMATCH[2]} n3=${BASH_REMATCH[3]}
  (( h1 > n1 || (h1 == n1 && h2 > n2) || (h1 == n1 && h2 == n2 && h3 >= n3) ))
}

config_home=${XDG_CONFIG_HOME:-$HOME/.config}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
config_dir="$config_home/nvim-tiny"
plugin_dir="$data_home/nvim-tiny/site/pack/vendor/start/mini.nvim"
launcher="$HOME/.local/bin/nvim-tiny"
backup_stamp=$(date +%Y%m%d-%H%M%S)-$$

if ! command -v nvim >/dev/null 2>&1; then
  echo 'Neovim 0.11.0 or newer is required on the target machine' >&2
  exit 1
fi
nvim_output=$(nvim --version 2>/dev/null || true)
if [[ ! $nvim_output =~ ^NVIM[[:space:]]v([0-9]+\.[0-9]+\.[0-9]+) ]] || ! version_at_least "${BASH_REMATCH[1]}" 0.11.0; then
  echo 'Neovim 0.11.0 or newer is required on the target machine' >&2
  exit 1
fi
echo "Using existing nvim: $(command -v nvim)"

if ! command -v rg >/dev/null 2>&1; then
  echo 'ripgrep (rg) is required on the target machine' >&2
  exit 1
fi
rg_output=$(rg --version 2>/dev/null || true)
if [[ ! $rg_output =~ ^ripgrep[[:space:]]([0-9]+\.[0-9]+\.[0-9]+) ]] || ! version_at_least "${BASH_REMATCH[1]}" 13.0.0; then
  echo 'ripgrep 13.0.0 or newer is required on the target machine' >&2
  exit 1
fi
echo "Using existing rg: $(command -v rg)"

copy_plugin=1
if [[ -d "$plugin_dir" ]]; then
  copy_plugin=0
  while IFS= read -r -d '' source; do
    relative=${source#"$repo_dir/vendor/mini.nvim/"}
    if [[ ! -f "$plugin_dir/$relative" ]] || ! cmp -s "$source" "$plugin_dir/$relative"; then
      copy_plugin=1
      break
    fi
  done < <(find "$repo_dir/vendor/mini.nvim" -type f -print0)
  if [[ $copy_plugin -eq 0 ]]; then echo "Using existing $mini_version plugin"; fi
fi

copy_config=1
if [[ -f "$config_dir/init.lua" && -f "$config_dir/CHEATSHEET.md" ]]; then
  if cmp -s "$repo_dir/config/init.lua" "$config_dir/init.lua" && cmp -s "$repo_dir/config/CHEATSHEET.md" "$config_dir/CHEATSHEET.md"; then
    copy_config=0
    echo 'Configuration is already current'
  fi
fi

render_launcher() {
  printf '%s\n' '#!/bin/sh' 'set -eu' 'export NVIM_APPNAME=nvim-tiny'
  printf '%s\n' 'exec nvim "$@"'
}

copy_launcher=1
if [[ -f "$launcher" ]] && cmp -s "$launcher" <(render_launcher); then
  copy_launcher=0
  echo 'Launcher is already current'
fi

paths=('')
if [[ $copy_config -eq 1 ]]; then paths+=("$config_dir"); fi
if [[ $copy_plugin -eq 1 ]]; then paths+=("$plugin_dir"); fi
if [[ $copy_launcher -eq 1 ]]; then paths+=("$launcher"); fi

# Refuse all conflicts before changing any destination.
if [[ $force -ne 1 ]]; then
  for path in "${paths[@]}"; do
    [[ -n "$path" ]] || continue
    if [[ -e "$path" || -L "$path" ]]; then
      echo "Already exists: $path (rerun with --force to back it up)" >&2
      exit 1
    fi
  done
fi
for path in "${paths[@]}"; do
  [[ -n "$path" ]] || continue
  mkdir -p "$(dirname -- "$path")"
  if [[ -e "$path" || -L "$path" ]]; then
    mv -- "$path" "$path.bak.$backup_stamp"
    echo "Backed up $path"
  fi
done

if [[ $copy_config -eq 1 ]]; then
  mkdir -p "$config_dir"
  cp "$repo_dir/config/init.lua" "$repo_dir/config/CHEATSHEET.md" "$config_dir/"
fi
if [[ $copy_plugin -eq 1 ]]; then
  mkdir -p "$plugin_dir"
  cp -R "$repo_dir/vendor/mini.nvim/." "$plugin_dir/"
  printf '%s\n' "$mini_version" > "$plugin_dir/.nvim-tiny-version"
fi
if [[ $copy_launcher -eq 1 ]]; then
  render_launcher > "$launcher"
  chmod 755 "$launcher"
fi

echo "Installed. Run $launcher, or add ~/.local/bin to PATH and run nvim-tiny"
echo 'Inside Neovim: :Tutor, :Keys, :TinyHealth'
