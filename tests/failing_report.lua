local utils = require("tests.utils")

local socket = "unix:/tmp/dmarc-report-milter-test.sock"

conn = mt.connect(socket)
assert(conn, "could not open connection")

local mail_text=[=[
Return-Path: <noreply-dmarc-support@google.com>
Delivered-To: dmarc-reports@example.net
Received: by jambon.example.net (Postfix, from userid 58)
  	id A328918ACD2; Mon, 14 Oct 2024 11:40:08 +0200 (CEST)
Received: from mail1.example.net (unknown [10.2.0.140])
  	by jambon.example.net (Postfix) with ESMTP id 629FB18ACD1
  	for <servers@zwm.fr>; Mon, 14 Oct 2024 11:40:04 +0200 (CEST)
Date: Sun, 13 Oct 2024 16:59:59 -0700
Message-ID: <16441118468373874675@google.com>
Subject: Report domain: example.net Submitter: google.com Report-ID: 16441118468373874675
From: noreply-dmarc-support@google.com
To: postmaster@example.net
Content-Type: application/gzip;
	name="google.com!example.net!1728777600!1728863999.xml.gz"
Content-Disposition: attachment;
	filename="google.com!example.net!1728777600!1728863999.xml.gz"
Content-Transfer-Encoding: base64

H4sIAPaEEmcAA51VyZLaMBC9pyr/QHGPN5Z4pjSafEBSOeSSm0tILdBgLSXJQP4+8sIgG1NJ
DQewXr+WXj91G/R6kfXiBNYJrV6WeZItX/HnT4gDsB2hx0UIK/d8cexlefDePKfp+XxOzqtE
231aZFme/v7x/Rc9gCTLd7L4N/mLUM4TRWEZjluEDxpE4KABpdfFELNgtPWVBE8Y8WSAu1DY
ulJEAv7Z+FrrY0K1ROk7GjHDqaLGTBJL+/2+SUGtdpr7PqknRBnDsYJhTlfldks5z9Z8TbNN
WXBeFk9b9lRsIGdblN640QZBLFSWqH0spIvsYC9CrV+LcpOX6yyU3CMTGijWkbbZumxJ7Tra
P7074F3IxCtkdC3on8o0u1q4A4xl6lC5wnAh0tTQmzFgEYuwo5DYorR/iCPO8C7Q/ka4wRbe
gHqUmhh2N9yNAoZ6nLdltg8RzjXOURq+rzU+KCZcGNV2VJrV56mnTjeWQiUMLrJVkiV5vko2
Yf8bPkmgulG+VdA/TKKDFjiRugm3wSbx3mDhjHbCty2ttIJgb4TMJbQOG+JcYI7NjlzkA2Ps
+sihOVWhRUamIMFAecFFmLn7/jtBrQ1UXmM9DBi3bR/e8Ecp3Go57qlxaJJ3AMLAzmTFgbiK
edmINP5QWXBN7e/KeeTlfw3AzXmoQ/Nqi9+I3GkVLuAKzJB7JZiHV0s7m91ielkzstD9pX5E
KQ1uY9laF1R2iw9KnEx2OuNymzuMXxjW4Q8E/wVh8kicYgYAAA==
]=]

local headers, body = utils.extract_headers(mail_text)

for name, value in pairs(headers) do
    local err = mt.header(conn, name, value)
    assert(err == nil, err)
    assert(mt.getreply(conn) == SMFIR_CONTINUE)
end

local err = mt.bodystring(conn, body)
assert(err == nil, err)

local err = mt.eom(conn)
assert(err == nil, err)
assert(mt.getreply(conn) == SMFIR_ACCEPT)

local err = mt.disconnect(conn)
assert(err == nil, err)
