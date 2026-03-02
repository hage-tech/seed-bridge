#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <main|dev> <output_dir>" >&2
    exit 1
}

target_branch="${1:-}"
output_dir="${2:-}"

case "$target_branch" in
    main|dev)
        ;;
    *)
        usage
        ;;
esac

if [ -z "$output_dir" ]; then
    usage
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$script_dir/.." rev-parse --show-toplevel)"
site_dir="$repo_root/site"

if [ ! -d "$site_dir" ]; then
    echo "Missing site directory at $site_dir" >&2
    exit 1
fi

if [ "${output_dir#/}" = "$output_dir" ]; then
    output_dir="$repo_root/$output_dir"
fi

resolve_ref() {
    local branch="$1"

    if git -C "$repo_root" rev-parse --verify --quiet "origin/$branch^{commit}" >/dev/null; then
        printf 'origin/%s\n' "$branch"
        return 0
    fi

    if git -C "$repo_root" rev-parse --verify --quiet "$branch^{commit}" >/dev/null; then
        printf '%s\n' "$branch"
        return 0
    fi

    return 1
}

copy_current_site() {
    local destination="$1"

    mkdir -p "$destination"
    rsync -a --delete "$site_dir/" "$destination/"
}

extract_site_from_ref() {
    local ref="$1"
    local destination="$2"

    mkdir -p "$destination"
    git -C "$repo_root" archive "$ref" site | tar -x -C "$destination" --strip-components=1
}

rm -rf "$output_dir"
mkdir -p "$output_dir"

if [ "$target_branch" = "main" ]; then
    copy_current_site "$output_dir"

    if dev_ref="$(resolve_ref dev 2>/dev/null)"; then
        extract_site_from_ref "$dev_ref" "$output_dir/test"
    fi
else
    if ! main_ref="$(resolve_ref main 2>/dev/null)"; then
        echo "Unable to resolve main branch contents for production root." >&2
        exit 1
    fi

    extract_site_from_ref "$main_ref" "$output_dir"
    copy_current_site "$output_dir/test"
fi

touch "$output_dir/.nojekyll"
