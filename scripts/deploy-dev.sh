#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$script_dir/.." rev-parse --show-toplevel)"
commit_message="${1:-Deploy dev}"

git -C "$repo_root" switch dev
git -C "$repo_root" add -A

if git -C "$repo_root" diff --cached --quiet; then
    echo "No staged changes to commit on dev."
    exit 0
fi

git -C "$repo_root" commit -m "$commit_message"
git -C "$repo_root" push origin dev
