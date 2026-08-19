#!/usr/bin/env bash
# Packages kevtris's nestest ROM and the Nintendulator golden log into a
# test-data GitHub release. Both are community-published freeware; their
# provenance and checksums ship inside the archive.
#
# Usage: ./update-nestest-release.sh <version>   (e.g. v1)
set -euo pipefail
export COPYFILE_DISABLE=1 # no AppleDouble junk when packaging on macOS

version="${1:?usage: ./update-nestest-release.sh <version>}"
release_repo=slonyk-emu/test-data
source_base="https://www.qmtpro.com/~nes/misc"
tag="nestest-$version"
asset="$tag.tar.xz"

if gh release view "$tag" --repo "$release_repo" > /dev/null 2>&1; then
    echo "release $tag already exists" >&2
    exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir "$work/pkg"

echo "fetching from $source_base..."
curl -fsSL "$source_base/nestest.nes" -o "$work/pkg/nestest.nes"
curl -fsSL "$source_base/nestest.log" -o "$work/pkg/nestest.log"

# A failed fetch can yield an HTML error page; check what actually arrived.
if [ "$(head -c 3 "$work/pkg/nestest.nes")" != "NES" ]; then
    echo "nestest.nes is not an iNES file" >&2
    exit 1
fi
if [ "$(head -c 4 "$work/pkg/nestest.log")" != "C000" ]; then
    echo "nestest.log does not start at \$C000" >&2
    exit 1
fi

{
    printf 'nestest CPU test ROM (kevtris) and Nintendulator golden log,\n'
    printf 'fetched from %s\n' "$source_base"
    (cd "$work/pkg" && shasum -a 256 nestest.nes nestest.log)
} > "$work/pkg/README"

tar --use-compress-program 'xz -6 -T0' -C "$work/pkg" -cf "$work/$asset" .

echo "uploading release $tag..."
gh release create "$tag" "$work/$asset" --repo "$release_repo" \
    --title "$tag" \
    --notes "nestest ROM (kevtris) and Nintendulator golden log from $source_base; community-published freeware."

echo "done: https://github.com/$release_repo/releases/download/$tag/$asset"
echo "to add the slonyk pin, run there:"
echo "  zig fetch --save=nestest https://github.com/$release_repo/releases/download/$tag/$asset"
