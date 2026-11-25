# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="
	af am ar bg bn ca cs da de el en-GB es es-419 et fa fi fil fr gu he hi hr
	hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv sw
	ta te th tr uk ur vi zh-CN zh-TW
"

inherit chromium-2 desktop linux-info optfeature pax-utils unpacker xdg

DESCRIPTION="Official Claude Desktop application for Linux (Beta)"
HOMEPAGE="
	https://claude.com/download
	https://code.claude.com/docs/en/desktop-linux
"
SRC_URI="https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/${PN}/${PN}_${PV}_amd64.deb"
S="${WORKDIR}"

LICENSE="all-rights-reserved BSD LGPL-2.1+ MIT"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="cowork gnome"
RESTRICT="bindist mirror strip test"

# libnotify, libsecret and libXtst are loaded with dlopen(), and pipewire is
# linked by claude-native-binding.node, so none of them can be dropped.
RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-crypt/libsecret
	app-misc/ca-certificates
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[opengl]
	media-video/pipewire
	net-print/cups
	sys-apps/dbus
	>=sys-libs/glibc-2.34
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/libXtst
	x11-libs/pango
	x11-misc/xdg-utils
	cowork? (
		app-emulation/qemu[qemu_softmmu_targets_x86_64,slirp]
		app-emulation/virtiofsd
		|| (
			sys-firmware/edk2-bin[qemu_softmmu_targets_x86_64(+)]
			sys-firmware/edk2
		)
	)
	gnome? ( dev-libs/gjs )
"

QA_PREBUILT="opt/${PN}/*"

pkg_setup() {
	linux-info_pkg_setup
	chromium_suid_sandbox_check_kernel_config

	if use cowork; then
		local CONFIG_CHECK="~KVM ~VHOST_VSOCK"
		local ERROR_KVM="CONFIG_KVM (plus KVM_INTEL or KVM_AMD) is needed to run the Cowork VM"
		local ERROR_VHOST_VSOCK="CONFIG_VHOST_VSOCK is needed for Claude to talk to the Cowork VM"
		check_extra_config
	fi
}

src_prepare() {
	default

	pushd "usr/lib/${PN}/locales" >/dev/null || die
	chromium_remove_language_paks
	popd >/dev/null || die

	# The app falls back to its bundled virtiofsd only on Ubuntu 22.04, which
	# has no virtiofsd package; everywhere else it uses the system one.
	rm "usr/lib/${PN}/resources/"virtiofsd{,.LICENSE-APACHE,.LICENSE-BSD-3-Clause} || die

	sed -i -e "s:/usr/lib/${PN}/:${EPREFIX}/opt/${PN}/:g" \
		"usr/lib/${PN}/resources/gnome-search-provider/com.anthropic.Claude.SearchProvider.service" || die
}

src_install() {
	local dest="/opt/${PN}"
	local res="usr/lib/${PN}/resources"

	pushd "usr/lib/${PN}" >/dev/null || die
	pax-mark m "${PN}"
	dodir "${dest}"
	cp -r . "${ED}${dest}" || die
	popd >/dev/null || die

	fowners root "${dest}/chrome-sandbox"
	fperms 4711 "${dest}/chrome-sandbox"

	dosym -r "${dest}/${PN}" "/usr/bin/${PN}"

	if [[ -x ${ED}${dest}/resources/bin/ccd ]]; then
		dosym -r "${dest}/resources/bin/ccd" /usr/bin/ccd
	fi

	domenu usr/share/applications/com.anthropic.Claude.desktop
	local icon size
	for icon in usr/share/icons/hicolor/*/apps/"${PN}".png; do
		size=${icon#usr/share/icons/hicolor/}
		doicon -s "${size%%/*}" "${icon}"
	done
	doicon "usr/share/pixmaps/${PN}.png"

	insinto /usr/share/mime/packages
	doins "${res}/linux-mime/com.anthropic.Claude.xml"

	if use gnome; then
		insinto /usr/share/gnome-shell/search-providers
		doins "${res}/gnome-search-provider/com.anthropic.Claude.search-provider.ini"
		insinto /usr/share/dbus-1/services
		doins "${res}/gnome-search-provider/com.anthropic.Claude.SearchProvider.service"
	fi

	if use cowork; then
		# Cowork only probes Debian's firmware paths and opens the image as raw.
		# Gentoo's 4 MiB OVMF builds are qcow2, so the raw 2 MiB one is linked,
		# which the app also accepts. The app derives the VARS template path
		# from the CODE path.
		dosym -r /usr/share/edk2/OvmfX64/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE.fd
		dosym -r /usr/share/edk2/OvmfX64/OVMF_VARS.fd /usr/share/OVMF/OVMF_VARS.fd
	fi

	dodoc "usr/share/doc/${PN}/copyright"
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature "persistent sign-in" virtual/secret-service
	optfeature "screen sharing and global shortcuts on Wayland" sys-apps/xdg-desktop-portal
	optfeature "Claude Code sandboxing" "sys-apps/bubblewrap net-misc/socat sys-apps/ripgrep"
	optfeature "Claude Code SSH sessions" net-misc/openssh

	if use cowork; then
		elog
		elog "Cowork runs tasks in a local QEMU/KVM virtual machine. It needs:"
		elog "  - your user in the 'kvm' group:  usermod -aG kvm <user>  (then log in again)"
		elog "  - the vhost_vsock kernel module:  modprobe vhost_vsock"
		elog "Claude checks these once at startup, so restart it after fixing them."
	else
		elog
		elog "Cowork (tasks in a local VM) needs USE=cowork."
	fi
}
