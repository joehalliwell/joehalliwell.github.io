#!/usr/bin/env bash
# Assert that the build ships no hidden directories.
#
# Nothing the site means to serve lives in one, and anything that does got
# there by accident -- an unanchored resources glob once published an agent
# worktree under /.claude/. Dotfiles at the root (.nojekyll) are fine.
#
# Usage: check-hidden.sh [output-dir]
set -euo pipefail

output_dir="${1:-build}"

if [ ! -d "$output_dir" ]; then
    echo "No $output_dir/ -- render the site first." >&2
    exit 1
fi

mapfile -t hidden < <(find "$output_dir" -mindepth 1 -type d -name '.*' -prune -print)

if [ "${#hidden[@]}" -gt 0 ]; then
    printf 'HIDDEN %s\n' "${hidden[@]#"$output_dir"/}"
    echo
    echo "${#hidden[@]} hidden director(ies) in $output_dir/; nothing served should live in one." >&2
    exit 1
fi
