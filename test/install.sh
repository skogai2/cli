#!/usr/bin/env bash
# build the package from HEAD, unpack it into a temp root, and check it
# holds what the repo does. -d: deps are checked by the tests themselves,
# they may come from mise rather than pacman.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cd "$repo"
BUILDDIR=$work/build SRCDEST=$work/src PKGDEST=$work/pkg makepkg -fd --noconfirm >/dev/null
git checkout -q PKGBUILD # makepkg rewrites pkgver

mkdir "$work/root"
bsdtar -xf "$work"/pkg/skogai-*.pkg.tar.* -C "$work/root" --exclude '.*'
diff -r .skogai/base "$work/root/usr/share/skogai/base"
for f in bin/*; do
    [[ -f $f ]] || continue
    cmp "$f" "$work/root/usr/bin/skogai-${f#bin/}"
done
echo ok
