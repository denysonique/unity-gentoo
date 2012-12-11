EAPI=4

inherit base gnome2 cmake-utils eutils

UURL="http://archive.ubuntu.com/ubuntu/pool/main/c/${PN}"
UVER="0ubuntu1"
URELEASE="precise-updates"
MY_P="${P/-/_}"
GNOME2_LA_PUNT="1"

DESCRIPTION="Compiz Fusion OpenGL window and compositing manager patched for the Unity desktop"
HOMEPAGE="http://unity.ubuntu.com/"
SRC_URI="${UURL}/${MY_P}+bzr3121.orig.tar.gz
	${UURL}/${MY_P}+bzr3121-${UVER}.debian.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+debug kde"

COMMONDEPEND="kde? ( <=kde-base/kwin-4.8.5 )
	!x11-wm/compiz
	!x11-libs/compiz-bcop
	!x11-libs/compiz-plugins-main
	dev-libs/boost
	dev-libs/glib:2
	dev-cpp/glibmm
	dev-libs/libxml2
	dev-libs/libxslt
	>=gnome-base/librsvg-2.14.0:2
	<media-libs/glew-1.8
	media-libs/libpng
	media-libs/mesa[gallium,llvm,xorg]
	=x11-base/xorg-server-1.13.0-r9999[dmx]
	>=x11-libs/cairo-1.0
	>=x11-libs/gtk+-99.3.4.2
	x11-libs/libnotify
	x11-libs/pango
	x11-libs/libwnck:1
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	=x11-libs/libXfixes-5.0-r9999
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXinerama
	x11-libs/libICE
	x11-libs/libSM
	>=x11-libs/startup-notification-0.7
	>=x11-wm/metacity-99.2.34.1"

DEPEND="${COMMONDEPEND}
	dev-util/pkgconfig
	x11-proto/damageproto
	x11-proto/xineramaproto"

RDEPEND="${COMMONDEPEND}
	x11-apps/mesa-progs
	x11-apps/xvinfo"

S="${WORKDIR}/${PN}-0.9.7.9"

src_prepare() {
	# Set compiz Window Decorations to !state=maxvert so top appmenu bar behaviour functions correctly #
	PATCHES+=( "${FILESDIR}/compiz-0.9.8_decor-setting.diff" )

	for patch in $(cat "${WORKDIR}/debian/patches/series" | grep -v '#'); do
        	PATCHES+=( "${WORKDIR}/debian/patches/${patch}" )
	done
	base_src_prepare

	sed -e "s:COMPIZ_CORE_INCLUDE_DIR \${includedir}/compiz/core:COMPIZ_CORE_INCLUDE_DIR ${D}usr/include/compiz/core:g" \
		-i cmake/CompizDefaults.cmake

	sed -e "s: -Werror::g" \
		-i cmake/CompizCommon.cmake

	# Set DESKTOP_SESSION so correct profile and it's plugins get loaded at Xsession start #
	sed -e 's:xubuntu:xunity:g' \
		-i "${WORKDIR}/debian/65compiz_profile-on-session" || die
}

src_configure() {
	use kde && \
		mycmakeargs="${mycmakeargs} -DUSE_KDE4=ON" || \
		mycmakeargs="${mycmakeargs} -DUSE_KDE4=OFF"

	mycmakeargs="${mycmakeargs}
		-DCMAKE_INSTALL_PREFIX="/usr"
		-DCOMPIZ_DISABLE_SCHEMAS_INSTALL=ON
		-DCOMPIZ_INSTALL_GCONF_SCHEMA_DIR="/etc/gconf/schemas"
		-DCOMPIZ_BUILD_WITH_RPATH=FALSE
		-DCOMPIZ_PACKAGING_ENABLED=TRUE
		-DUSE_GCONF=ON
		-DUSE_GSETTINGS=OFF
		-DCOMPIZ_DISABLE_GS_SCHEMAS_INSTALL=ON
		-DCOMPIZ_DESTDIR="${D}"
		-DCOMPIZ_BUILD_TESTING=OFF
		-DCOMPIZ_DEFAULT_PLUGINS="ccp"
		"
	cmake-utils_src_configure
}

src_install() {
	pushd ${CMAKE_BUILD_DIR}
		dodir /usr/share/cmake/Modules
		emake findcompiz_install
		emake install

		# Window manager desktop file for GNOME #
		insinto /usr/share/gnome/wm-properties/
		doins gtk/gnome/compiz.desktop
	popd ${CMAKE_BUILD_DIR}

	# Docs #
	pushd ${CMAKE_USE_DIR}
		dodoc AUTHORS NEWS README
	popd ${CMAKE_USE_DIR}
	doman "${WORKDIR}"/debian/{compiz,compiz-decorator,gtk-window-decorator}.1

	# X11 startup script #
	exeinto /etc/X11/xinit/xinitrc.d/
	doexe "${WORKDIR}/debian/65compiz_profile-on-session"

	# Unity Compiz profile configuration file #
	insinto /etc/compizconfig
	doins "${WORKDIR}/debian/unity.ini"

	# Compiz profile upgrade helper files for ensuring smooth upgrades from older configuration files #
	insinto /etc/compizconfig/upgrades/
	doins "${WORKDIR}"/debian/profile_upgrades/*.upgrade

	# Default GConf settings #
	insinto /usr/share/gconf/defaults
	newins "${WORKDIR}/debian/compiz-gnome.gconf-defaults" 10_compiz-gnome

	# Compiz decorator wrapper and reset scripts #
	exeinto /usr/bin
	doexe "${WORKDIR}/debian/compiz-decorator"
	doexe "${FILESDIR}/compiz.reset"

	# Setup gconf defaults #
	dodir /etc/gconf/2
	if [ -z "`grep gconf.xml.unity /etc/gconf/2/local-defaults.path 2> /dev/null`" ]; then
		echo "/etc/gconf/gconf.xml.unity" >> ${D}etc/gconf/2/local-defaults.path
	fi
	dodir /etc/gconf/gconf.xml.unity 2> /dev/null
	/usr/bin/update-gconf-defaults \
		--source="${D}usr/share/gconf/defaults" \
			--destination="${D}etc/gconf/gconf.xml.unity" || die
	gnome2_gconf_install
}
