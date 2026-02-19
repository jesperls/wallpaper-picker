#!/usr/bin/env bash
set -euo pipefail

wall_dir="${WP_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Wallpapers}"
wall_dir="${wall_dir/#\~/$HOME}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-manager"
mkdir -p "$cache_dir"

focused_output() {
  hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name' | head -n1
}

all_outputs() {
  hyprctl monitors -j | jq -r '.[].name'
}

list_wallpapers() {
  local dir="$1"
  [ -d "$dir" ] || return 1
  find -L "$dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.bmp' \) | LC_COLLATE=C sort
}

set_wallpaper() {
  local output="$1" file="$2"
  echo "$file" > "$cache_dir/${output//\//_}.current"
  hyprctl hyprpaper wallpaper "$output,$file"
}

cycle() {
  local output
  output=$(focused_output)
  [ -z "$output" ] && { echo "no focused monitor" >&2; exit 1; }

  local state_file="$cache_dir/${output//\//_}.idx"
  local -a files=()

  for dir in "$wall_dir/$output" "$wall_dir"; do
    mapfile -t files < <(list_wallpapers "$dir") || true
    [ "${#files[@]}" -gt 0 ] && break
  done
  [ "${#files[@]}" -eq 0 ] && { echo "no wallpapers found" >&2; exit 1; }

  local idx=-1
  [ -f "$state_file" ] && read -r idx < "$state_file"
  idx=$(( (idx + 1) % ${#files[@]} ))
  echo "$idx" > "$state_file"

  set_wallpaper "$output" "${files[$idx]}"
}

init() {
  # Wait for hyprpaper socket to be available
  for _ in {1..50}; do
    hyprctl hyprpaper wallpaper ",invalid" &>/dev/null && break
    sleep 0.1
  done
  for output in $(all_outputs); do
    local current_file="$cache_dir/${output//\//_}.current"
    if [ -f "$current_file" ]; then
      local file
      read -r file < "$current_file" || true
      if [ -f "$file" ]; then
        set_wallpaper "$output" "$file"
        continue
      fi
    fi
    local state_file="$cache_dir/${output//\//_}.idx"
    local -a files=()
    for dir in "$wall_dir/$output" "$wall_dir"; do
      mapfile -t files < <(list_wallpapers "$dir") || true
      [ "${#files[@]}" -gt 0 ] && break
    done
    if [ "${#files[@]}" -gt 0 ]; then
      set_wallpaper "$output" "${files[0]}"
      echo "0" > "$state_file"
    fi
  done
}

case "${1:-cycle}" in
  set)
    [ -z "${2:-}" ] || [ -z "${3:-}" ] && { echo "usage: wallpaper-manager set <output> <file>" >&2; exit 1; }
    set_wallpaper "$2" "$3"
    ;;
  cycle) cycle ;;
  init)  init ;;
  pick)
    export WP_MONITOR
    WP_MONITOR=$(focused_output)
    exec wallpaper-picker
    ;;
  *)     echo "unknown command: ${1:-}" >&2; exit 1 ;;
esac
