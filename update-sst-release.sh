#!/usr/bin/env bash
# Repackages SingleStepTests/65x02 nes6502/v1 at a given upstream commit and
# publishes it as a test-data GitHub release. The corpus is MIT licensed; its
# LICENSE ships inside the tarball.
#
# Usage: ./update-sst-release.sh <upstream-commit-sha>
set -euo pipefail
export COPYFILE_DISABLE=1 # no AppleDouble junk when packaging on macOS

upstream_sha="${1:?usage: ./update-sst-release.sh <upstream-commit-sha>}"
upstream_repo=SingleStepTests/65x02
release_repo=slonyk-emu/test-data
tag="sst-nes6502-${upstream_sha:0:12}"
asset="$tag.tar.xz"

if gh release view "$tag" --repo "$release_repo" > /dev/null 2>&1; then
    echo "release $tag already exists" >&2
    exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "fetching $upstream_repo@$upstream_sha (nes6502/v1 only)..."
git clone --filter=blob:none --no-checkout "https://github.com/$upstream_repo.git" "$work/src"
# Cone mode: nes6502/v1 recursively, plus root files (LICENSE among them).
git -C "$work/src" sparse-checkout set nes6502/v1
git -C "$work/src" checkout "$upstream_sha"

mkdir "$work/pkg"
mv "$work/src/nes6502/v1" "$work/pkg/cases"
mv "$work/src/LICENSE" "$work/pkg/LICENSE"
printf 'SingleStepTests nes6502 v1, repackaged from %s@%s\n' \
    "$upstream_repo" "$upstream_sha" > "$work/pkg/README"

echo "compressing..."
# -9 measured 0.6% smaller at 3.3x the time; not worth it on this corpus.
tar --use-compress-program 'xz -6 -T0' -C "$work/pkg" -cf "$work/$asset" .

echo "uploading release $tag..."
gh release create "$tag" "$work/$asset" --repo "$release_repo" \
    --title "$tag" \
    --notes "SingleStepTests nes6502 v1 test corpus, repackaged from $upstream_repo@$upstream_sha (MIT)."

echo "done: https://github.com/$release_repo/releases/download/$tag/$asset"
echo "to update the slonyk pin, run there:"
echo "  zig fetch --save=sst_nes6502 https://github.com/$release_repo/releases/download/$tag/$asset"
