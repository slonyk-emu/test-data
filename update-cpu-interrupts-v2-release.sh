#!/usr/bin/env bash
# Repackages blargg's cpu_interrupts_v2 suite from christopherpow/nes-test-roms
# at a given upstream commit and publishes it as a test-data GitHub release.
# The suite ships with its upstream readme and sources; provenance and
# checksums go into the archive's README.
#
# Usage: ./update-cpu-interrupts-v2-release.sh <upstream-commit-sha>
set -euo pipefail
export COPYFILE_DISABLE=1 # no AppleDouble junk when packaging on macOS

upstream_sha="${1:?usage: ./update-cpu-interrupts-v2-release.sh <upstream-commit-sha>}"
upstream_repo=christopherpow/nes-test-roms
release_repo=slonyk-emu/test-data
tag="cpu-interrupts-v2-${upstream_sha:0:12}"
asset="$tag.tar.xz"

if gh release view "$tag" --repo "$release_repo" > /dev/null 2>&1; then
    echo "release $tag already exists" >&2
    exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "fetching $upstream_repo@$upstream_sha (cpu_interrupts_v2 only)..."
git clone --filter=blob:none --no-checkout "https://github.com/$upstream_repo.git" "$work/src"
git -C "$work/src" sparse-checkout set cpu_interrupts_v2
git -C "$work/src" checkout "$upstream_sha"

mkdir "$work/pkg"
mv "$work/src/cpu_interrupts_v2"/* "$work/pkg/"

if [ "$(ls "$work/pkg/rom_singles"/*.nes | wc -l)" -ne 5 ]; then
    echo "expected 5 single-test ROMs" >&2
    exit 1
fi
for rom in "$work/pkg/rom_singles"/*.nes "$work/pkg/cpu_interrupts.nes"; do
    if [ "$(head -c 3 "$rom")" != "NES" ]; then
        echo "$rom is not an iNES file" >&2
        exit 1
    fi
done

{
    printf "blargg's (Shay Green) cpu_interrupts_v2 test suite,\n"
    printf 'repackaged from %s@%s\n' "$upstream_repo" "$upstream_sha"
    (cd "$work/pkg" && shasum -a 256 cpu_interrupts.nes rom_singles/*.nes)
} > "$work/pkg/README"

echo "compressing..."
tar --use-compress-program 'xz -6 -T0' -C "$work/pkg" -cf "$work/$asset" .

echo "uploading release $tag..."
gh release create "$tag" "$work/$asset" --repo "$release_repo" \
    --title "$tag" \
    --notes "blargg's cpu_interrupts_v2 test suite, repackaged from $upstream_repo@$upstream_sha."

echo "done: https://github.com/$release_repo/releases/download/$tag/$asset"
echo "to add the slonyk pin, run there:"
echo "  zig fetch --save=cpu_interrupts_v2 https://github.com/$release_repo/releases/download/$tag/$asset"
