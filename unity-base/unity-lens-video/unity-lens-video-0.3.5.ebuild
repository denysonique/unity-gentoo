EAPI=4

inherit distutils eutils

UURL="http://archive.ubuntu.com/ubuntu/pool/main/u/${PN}"
UVER="0ubuntu1.3"
URELEASE="precise"
MY_P="${P/video-/video_}"
GNOME2_LA_PUNT="1"

DESCRIPTION="Application lens for the Unity desktop"
HOMEPAGE="http://unity.ubuntu.com/"
SRC_URI="${UURL}/${MY_P}.orig.tar.gz
	${UURL}/${MY_P}-${UVER}.diff.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="unity-base/unity"

src_prepare() {
	epatch "${WORKDIR}/${MY_P}-${UVER}.diff"
	distutils_src_prepare
}
