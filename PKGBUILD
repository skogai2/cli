# Maintainer: Emil Skogsund <emil@skogsund.se>

# builds from this repo's committed HEAD, never the working tree, so an
# installed version is always a commit.

pkgname=skogai
pkgver=0.0.1
pkgrel=1
pkgdesc='modular framework: a command runner and layered key-value settings'
arch=('any')
license=('unknown')
depends=('bash' 'go-yq')  # also argc, not in the official repos
makedepends=('git')
source=("$pkgname::git+file://$startdir")
sha256sums=('SKIP')

pkgver() {
  cd "$pkgname"
  # v0.0.1 on a tag; 0.0.1.r3.gabc1234 three commits after it
  git describe --tags --long --abbrev=7 | sed -E 's/^v//; s/-0-g[0-9a-f]+$//; s/-([0-9]+)-g/.r\1.g/'
}

package() {
  cd "$pkgname"

  # the base a repo copies into its .skogai/base
  install -Dm644 .skogai/base/config.md "$pkgdir/usr/share/skogai/base/config.md"

  local f
  for f in bin/*; do
    if [[ -f $f ]]; then
      install -Dm755 "$f" "$pkgdir/usr/bin/skogai-${f#bin/}"
    fi
  done
  for f in lib/*; do
    if [[ -f $f ]]; then
      install -Dm644 "$f" "$pkgdir/usr/lib/skogai/${f#lib/}"
    fi
  done
}
