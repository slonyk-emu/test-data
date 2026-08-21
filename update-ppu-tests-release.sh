#!/usr/bin/env bash
# Repackages the PPU test-ROM suites from christopherpow/nes-test-roms at a
# given upstream commit and publishes them as one test-data GitHub release:
# blargg's (two generations of reporting) and bisqwit's read-buffer test,
# each directory kept whole with its readme and sources.
#
# Usage: ./update-ppu-tests-release.sh <upstream-commit-sha>
set -euo pipefail
export COPYFILE_DISABLE=1 # no AppleDouble junk when packaging on macOS

upstream_sha="${1:?usage: ./update-ppu-tests-release.sh <upstream-commit-sha>}"
upstream_repo=christopherpow/nes-test-roms
release_repo=slonyk-emu/test-data
tag="ppu-tests-${upstream_sha:0:12}"
asset="$tag.tar.xz"
suites=(
    blargg_ppu_tests_2005.09.15b
    vbl_nmi_timing
    sprite_hit_tests_2005.10.05
    sprite_overflow_tests
    ppu_vbl_nmi
    ppu_open_bus
    oam_read
    oam_stress
    ppu_read_buffer
)

if gh release view "$tag" --repo "$release_repo" > /dev/null 2>&1; then
    echo "release $tag already exists" >&2
    exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "fetching $upstream_repo@$upstream_sha (${#suites[@]} suites)..."
git clone --filter=blob:none --no-checkout "https://github.com/$upstream_repo.git" "$work/src"
git -C "$work/src" sparse-checkout set "${suites[@]}"
git -C "$work/src" checkout "$upstream_sha"

mkdir "$work/pkg"
for suite in "${suites[@]}"; do
    mv "$work/src/$suite" "$work/pkg/$suite"
done

# Every ROM must be an iNES file; a sparse checkout that drifted would
# show up here.
while IFS= read -r rom; do
    if [ "$(head -c 3 "$rom")" != "NES" ]; then
        echo "$rom is not an iNES file" >&2
        exit 1
    fi
done < <(find "$work/pkg" -name '*.nes')

{
    printf 'PPU test ROM suites (blargg, bisqwit), repackaged from %s@%s\n' \
        "$upstream_repo" "$upstream_sha"
    (cd "$work/pkg" && find . -name '*.nes' | sort | xargs shasum -a 256)
} > "$work/pkg/README"

echo "compressing..."
tar --use-compress-program 'xz -6 -T0' -C "$work/pkg" -cf "$work/$asset" .

echo "uploading release $tag..."
gh release create "$tag" "$work/$asset" --repo "$release_repo" \
    --title "$tag" \
    --notes "PPU test ROM suites (blargg, bisqwit), repackaged from $upstream_repo@$upstream_sha."

echo "done: https://github.com/$release_repo/releases/download/$tag/$asset"
echo "to add the slonyk pin, run there:"
echo "  zig fetch --save=ppu_tests https://github.com/$release_repo/releases/download/$tag/$asset"
