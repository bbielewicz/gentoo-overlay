# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="
	af am ar bg bn ca cs da de el en-GB es es-419 et fa fi fil fr gu he hi hr
	hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv sw
	ta te th tr uk ur vi zh-CN zh-TW
"

inherit chromium-2 desktop optfeature

DESCRIPTION="Source-code editor developed by Microsoft"
HOMEPAGE="https://code.visualstudio.com"
SRC_URI="https://update.code.visualstudio.com/${PV}/linux-x64/stable -> ${P}-amd64.tar.gz"
S="${WORKDIR}/VSCode-linux-x64"

LICENSE="
	Apache-2.0 BSD BSD-1 BSD-2 BSD-4 CC-BY-4.0 ISC LGPL-2.1+ Microsoft-vscode
	MIT MPL-2.0 openssl PYTHON TextMate-bundle Unlicense UoI-NCSA W3C
"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="bindist mirror strip"

RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-crypt/libsecret[crypt]
	app-misc/ca-certificates
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	|| (
		dev-libs/openssl-compat:3
		dev-libs/openssl:0/3
	)
	media-libs/alsa-lib
	media-libs/libglvnd
	media-libs/mesa[opengl]
	net-misc/curl
	net-print/cups
	sys-apps/dbus
	sys-process/lsof
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libxkbfile
	x11-libs/libXrandr
	x11-libs/pango
	x11-misc/xdg-utils
	!app-editors/vscode
"

QA_PREBUILT="opt/${PN}/*"

src_prepare() {
	default

	pushd locales >/dev/null || die
	chromium_remove_language_paks
	popd >/dev/null || die

	sed -i -e '/"updateUrl"/d' resources/app/product.json || die
}

src_install() {
	dodir /opt
	cp -pPR "${S}" "${ED}/opt/${PN}" || die "Failed to copy files"
	fperms 4711 /opt/${PN}/chrome-sandbox
	dosym "${EPREFIX}/opt/${PN}/bin/code" /usr/bin/code
	make_desktop_entry "code" "Visual Studio Code" "${PN}" "Development;IDE"
	newicon "${S}/resources/app/resources/linux/code.png" "${PN}.png"
}

pkg_postinst() {
	optfeature "desktop notifications" x11-libs/libnotify
	optfeature "keyring support" virtual/secret-service
}
