pkgname=mux
pkgver=0.16.0
pkgrel=0
pkgdesc="Desktop app for isolated, parallel agentic development"
arch=('x86_64')
url='https://github.com/coder/mux'
license=('AGPL-3.0-only')
depends=('fuse2')
source=("mux-${pkgver}-x86_64.AppImage::${url}/releases/download/v${pkgver}/mux-${pkgver}-x86_64.AppImage")
sha256sums=('0b3ba305e56ef8cfe8b7be3e28f7b8f81569cfdfd24ddf3d9f5509d0c7dd13f6')

package() {
  cd "${srcdir}"

  local appimage="mux-${pkgver}-x86_64.AppImage"

  install -Dm755 "${appimage}" "${pkgdir}/opt/${pkgname}/mux.AppImage"

  install -Dm755 /dev/stdin "${pkgdir}/usr/bin/mux" <<'EOF'
#!/bin/sh
exec /opt/mux/mux.AppImage "$@"
EOF

  install -dm755 "${pkgdir}/usr/share/applications"
  install -Dm644 /dev/stdin "${pkgdir}/usr/share/applications/mux.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Mux
Comment=Desktop app for isolated, parallel agentic development
Exec=mux
Icon=mux
Terminal=false
Categories=Development;
StartupWMClass=Mux
EOF
}
