#!/bin/sh
# Create a worktree with submodules populated from the local repo, not the network.
#
#   dev/wt.sh ../cxmol-foo            # new branch named cxmol-foo from HEAD
#   dev/wt.sh ../cxmol-foo feature-x  # branch/commit feature-x
#
# Submodule gitdirs live in <main>/.git/modules/<path>. This script points each
# submodule URL at that local gitdir before `git submodule update`, so the
# checkout is a local clone (hardlinked objects) and works offline.
set -eu

if [ $# -lt 1 ]; then
    echo "usage: $0 <path> [<commit-ish>]" >&2
    exit 2
fi

path=$1
shift

git worktree add "$path" "$@"

wt=$(cd "$path" && git rev-parse --show-toplevel)
common=$(cd "$(git -C "$wt" rev-parse --git-common-dir)" && pwd)

git -C "$wt" config -f .gitmodules --get-regexp '\.path$' | while read -r key sub; do
    if [ ! -d "$common/modules/$sub" ]; then
        echo "error: $common/modules/$sub is missing." >&2
        echo "run 'git submodule update --init' in the main worktree first." >&2
        exit 1
    fi
    git -C "$wt" config "submodule.$sub.url" "$common/modules/$sub"
done

git -C "$wt" submodule update --init --recursive
