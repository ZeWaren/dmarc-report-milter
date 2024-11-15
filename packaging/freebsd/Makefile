PORTNAME=			milter-dmarc-report
DISTVERSION=		1.0.1
CATEGORIES=			mail
MASTER_SITES=		GH

MAINTAINER=			public@fzwte.net
COMMENT=			Milter to discard passing DMARC reports
WWW=				https://github.com/ZeWaren/dmarc-report-milter

LICENSE=			MIT

LIB_DEPENDS=		libmilter.so:mail/libmilter libzstd.so:archivers/zstd

USES=				cargo ssl
USE_GITHUB=			yes
GH_ACCOUNT=			ZeWaren
GH_PROJECT=			dmarc-report-milter
GH_TAGNAME=         1.0.1
MAKE_ENV+=			PKG_CONFIG_PATH=.

USE_RC_SUBR=		${PORTNAME}

post-install:
	${MKDIR} ${STAGEDIR}/var/run/milter-dmarc-report

.include <bsd.port.mk>
