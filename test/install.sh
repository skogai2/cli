#!/usr/bin/env bash
# build the package from HEAD, unpack it into a temp root, and run the
# config tests against what pacman would install. needs nothing installed.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cd "$repo"
BUILDDIR=$work/build SRCDEST=$work/src PKGDEST=$work/pkg makepkg -f --noconfirm >/dev/null
git checkout -q PKGBUILD # makepkg rewrites pkgver

mkdir "$work/root"
bsdtar -xf "$work"/pkg/skogai-*.pkg.tar.* -C "$work/root" --exclude '.*'
SKOGAI_TEST_ROOT=$work/root bats "$repo/test/config.bats"
