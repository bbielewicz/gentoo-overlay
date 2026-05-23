# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop

DESCRIPTION="Visual Studio Code is a source-code editor developed by Microsoft"
HOMEPAGE="https://code.visualstudio.com"
SRC_URI="https://update.code.visualstudio.com/${PV}/linux-x64/stable -> ${P}-amd64.tar.gz"
RESTRICT="mirror strip bindist"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="gnome-keyring"

DEPEND=""
RDEPEND="${DEPEND}
	gnome-keyring? (
		app-crypt/libsecret[crypt]
		gnome-base/gnome-keyring )
	>=dev-libs/nss-3.79
	>=net-print/cups-2.4.0
	>=x11-libs/gtk+-3.24.33:3
	>=x11-libs/libxkbcommon-1.5.0
	>=x11-libs/libxkbfile-1.1.0
	!app-editors/vscode
"

QA_PREBUILT="
	/opt/${PN}/code
	/opt/${PN}/chrome-sandbox
"

pkg_setup() {
	if use amd64; then
		S="${WORKDIR}/VSCode-linux-x64"
	else
		die
	fi
}

src_install() {
	dodir "/opt"
	cp -pPR "${S}" "${D}/opt/${PN}" || die "Failed to copy files"
	fperms 4711 /opt/${PN}/chrome-sandbox
	dosym "${EPREFIX}/opt/${PN}/bin/code" "/usr/bin/code"
	make_desktop_entry "code" "Visual Studio Code" "${PN}" "Development;IDE"
	newicon "${S}/resources/app/resources/linux/code.png" "${PN}.png"
}
