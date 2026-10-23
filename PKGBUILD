# Maintainer: Emil Skogsund <emil@skogsund.se>

# builds from this repo's committed HEAD, never the working tree, so an
# installed version is always a commit.

pkgname=skogai
pkgver=r0
pkgrel=1
pkgdesc='modular framework: a command runner and layered key-value settings'
arch=('any')
license=('unknown')
depends=('bash' 'git')
makedepends=('git')
backup=('etc/skogai/config')
source=("$pkgname::git+file://$startdir")
sha256sums=('SKIP')

pkgver() {
  cd "$pkgname"
  printf 'r%s.%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  cd "$pkgname"

  # system defaults become the machine's system scope
  install -Dm644 .skogai/base/system/config "$pkgdir/etc/skogai/config"

  local f
  for f in bin/*; do
    if [[ -f $f ]]; then
      install -Dm755 "$f" "$pkgdir/usr/bin/${f#bin/}"
    fi
  done
  for f in lib/*; do
    if [[ -f $f ]]; then
      install -Dm644 "$f" "$pkgdir/usr/lib/skogai/${f#lib/}"
    fi
  done
}
