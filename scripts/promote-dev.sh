#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$script_dir/.." rev-parse --show-toplevel)"
merge_message="${1:-Promote dev to main}"

git -C "$repo_root" fetch origin main dev
git -C "$repo_root" switch main
git -C "$repo_root" pull --ff-only origin main
git -C "$repo_root" merge --no-ff --no-edit dev -m "$merge_message"
git -C "$repo_root" push origin main
