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

H4sIAO8YEmcAA61UwXKbMBC9dyb/4PHdyNgEcEdResoXtGdGFgtWApJGEonz911sIbCTmV56
QrzdfbvvaYE+n/tu9Q7WSa2e1mmyXa9ACV1L1T6t//x+2ZTr1TN7+EEbgPrIxRueVytqwWjr
qx48r7nnFxBhbdtK8R5Yq3XbQSJ0T0kEQxL0XHZMaeToPjd1z63YuMGMhL+Wdde8qejsLa+E
Vp4LX0nVaHby3rifhITaZK4lnHDlPsCSXZbnj+UWyb7WB+YgRdYszbMsTdMyy8t9sS+LLC8e
KZnjoQAFQ2W5aidFiB2hlYqlxa4siiLfYsMrEhNA1Zdwme8PhwPOoyIfuSOMLW/cpUZ3UnxW
Zjh20p1gHkejT4rBmfcG5SvwyHjFQgav32TPLCXXw4Q601zA8Rkwwyy8gkAGM0FuxlwEjfAs
HVWOh4CpOVGZIOTbmdFxoW2c3+qP2SanByugkobttvtkm6TpPsl22DriMVXoQeEUlFwPEQ89
4Z13Axpbx8jolXRGO+lx2XEBFaBTC2SZOBpluHOYMXsWDGlCZDZuofW+L95mFEhlDcrLRuL3
NleegNdgq8bq/vYWl4GJ7CsD5YM/VRbc0PkF6/3Y/1yT8DGMNEFfeFlqhw4vWFv2yvujVmjB
BMw+3DSmS4/+yxRL23F577WP+WG7KFn8s/4CGeS9KukEAAA=
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
assert(mt.getreply(conn) == SMFIR_DISCARD)

local err = mt.disconnect(conn)
assert(err == nil, err)
