set -euo pipefail

# --- Configuration ---
default_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Wallpapers"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-manager"
mkdir -p "$cache_dir"

cmd="${1:-cycle}"

# --- Helpers ---

focused_output() {
  hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name' | head -n1
}

all_outputs() {
  hyprctl monitors -j | jq -r '.[].name'
}

pick_list() {
  local dir="$1"
  [ -d "$dir" ] || return 1
  find -L "$dir" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.bmp' \) | LC_COLLATE=C sort
}

# --- Core ---

set_wallpaper() {
  local output="$1" file="$2"
  echo "$file" > "$cache_dir/${output//\//_}.current"
  hyprctl hyprpaper preload "$file" 2>/dev/null || true
  hyprctl hyprpaper wallpaper "$output,$file"
  hyprctl hyprpaper unload unused 2>/dev/null || true
}

next_wall_for_output() {
  local output="$1" dir="$2"
  local state_file="$cache_dir/${output//\//_}.idx"
  mapfile -t files < <(pick_list "$dir") || true
  [ "${#files[@]}" -eq 0 ] && return 1

  local last_idx=-1
  [ -f "$state_file" ] && read -r last_idx < "$state_file"
  local next_idx=$(( (last_idx + 1) % ${#files[@]} ))
  echo "$next_idx" > "$state_file"

  set_wallpaper "$output" "${files[$next_idx]}"
}

restore_wallpaper() {
  local output="$1"
  local current_file="$cache_dir/${output//\//_}.current"
  if [ -f "$current_file" ]; then
    local file
    read -r file < "$current_file" || true
    if [ -f "$file" ]; then
      set_wallpaper "$output" "$file"
      return 0
    fi
  fi
  next_wall_for_output "$output" "$default_dir/$output" \
    || next_wall_for_output "$output" "$default_dir" \
    || true
}

# --- Commands ---

cycle_focused() {
  local out
  out=$(focused_output)
  [ -z "$out" ] && { echo "no focused monitor detected" >&2; exit 1; }
  next_wall_for_output "$out" "$default_dir/$out" \
    || next_wall_for_output "$out" "$default_dir" \
    || { echo "no wallpapers found for $out" >&2; exit 1; }
}

init_all() {
  for _ in $(seq 1 50); do
    hyprctl hyprpaper listloaded &>/dev/null && break
    sleep 0.1
  done
  for output in $(all_outputs); do
    restore_wallpaper "$output"
  done
}

pick_for_output() {
  # Launch QuickShell wallpaper picker GUI
  # The picker handles thumbnail display, selection, and hyprpaper IPC internally
  wallpaper-picker || true
}

# --- Dispatch ---

case "$cmd" in
  set)
    [ -z "${2:-}" ] || [ -z "${3:-}" ] && { echo "usage: wallpaper-manager set <output> <file>" >&2; exit 1; }
    set_wallpaper "$2" "$3"
    ;;
  init)     init_all ;;
  pick)
    out=$(focused_output)
    [ -z "$out" ] && { echo "no focused monitor detected" >&2; exit 1; }
    pick_for_output "$out"
    ;;
  pick-all)
    for output in $(all_outputs); do pick_for_output "$output"; done
    ;;
  *)        cycle_focused ;;
esac
