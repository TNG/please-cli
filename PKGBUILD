# Maintainer: Nicholas Schwab <nicholas.schwab@tngtech.com>
pkgname=please-cli
pkgver=0.3.0
pkgrel=1
pkgdesc='An AI helper script to create CLI commands.'
arch=('any')
license=('Apache')
depends=('bash' 'jq' 'curl')
optdepends=('libsecret: store OpenApi key in keychain'
    'xclip: copy command to clipboard on X'
    'wl-clipboard: copy command to clipboard on Wayland')
makedepends=('sed')
install="${pkgname}.install"
source=("please.sh")
sha256sums=('647242b408b516071e2885531acc0a9b197e37d2523b947d4dad03ba8c690b9e')

prepare() {
  cd "$pkgname-$pkgver"

  # Patching the install command in an error message.
  sed -i -e 's/sudo apt install libsecret-tools/sudo pacman -S libsecret/' "please.sh"
}

package() {
  cd "$pkgname-$pkgver"

  install -m 755 -DT "please.sh" "${pkgdir}/usr/bin/please"
}
