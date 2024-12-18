local utils = require("tests.utils")

local socket = "unix:/tmp/dmarc-report-milter-test.sock"

conn = mt.connect(socket)
assert(conn, "could not open connection")

local mail_text=[=[
Return-Path: <dmarcreport@microsoft.com>
Delivered-To: postmaster@example.net
Received: by lapin.example.net (Postfix, from userid 58)
	id B215915DE4D; Sun, 20 Oct 2024 15:11:53 +0200 (CEST)
Received: from CH0P221CA0007.NAMP221.PROD.OUTLOOK.COM (2603:10b6:610:11c::23)
 by BL1PR18MB4199.namprd18.prod.outlook.com (2603:10b6:208:31b::8) with
 Microsoft SMTP Server (version=TLS1_2,
 cipher=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384) id 15.20.8069.28; Sun, 20 Oct
 2024 13:11:42 +0000
Received: from CH1PEPF0000AD77.namprd04.prod.outlook.com
 (2603:10b6:610:11c:cafe::76) by CH0P221CA0007.outlook.office365.com
 (2603:10b6:610:11c::23) with Microsoft SMTP Server (version=TLS1_2,
 cipher=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384) id 15.20.8069.28 via Frontend
 Transport; Sun, 20 Oct 2024 13:11:42 +0000
Received: from nam10.map.protection.outlook.com (2a01:111:f400:7e5b::30) by
 CH1PEPF0000AD77.mail.protection.outlook.com (2603:10b6:61f:fc00::337) with
 Microsoft SMTP Server (version=TLS1_2,
 cipher=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384) id 15.20.8093.14 via Frontend
 Transport; Sun, 20 Oct 2024 13:11:42 +0000
Message-ID: <5fb4343ff26f48b38a6341a66ed73297@microsoft.com>
X-Sender: <dmarcreport@microsoft.com> XATTRDIRECT=Originating XATTRORGID=xorgid:96f9e21d-a1c4-44a3-99e4-37191ac61848
MIME-Version: 1.0
From: "DMARC Aggregate Report" <dmarcreport@microsoft.com>
To: <postmaster@example.net>
Subject: Report Domain: enceinte.tf Submitter: protection.outlook.com Report-ID: 359256781d964de9816a13f5ebd70545
Content-Type: multipart/mixed;
	boundary="_mpm_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_"
Date: Sun, 20 Oct 2024 13:11:42 +0000


--_mpm_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_
Content-Type: multipart/related;
	boundary="_rv_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_"

--_rv_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_
Content-Type: multipart/alternative;
	boundary="_av_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_"

--_av_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_


--_av_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_
Content-Type: text/html; charset=us-ascii
Content-Transfer-Encoding: base64

PGRpdiBzdHlsZSA9ImZvbnQtZmFtaWx5OlNlZ29lIFVJOyBmb250LXNpemU6MTRweDsiPlRoaXMg
aXMgYSBETUFSQyBhZ2dyZWdhdGUgcmVwb3J0IGZyb20gTWljcm9zb2Z0IENvcnBvcmF0aW9uLiBG
b3IgRW1haWxzIHJlY2VpdmVkIGJldHdlZW4gMjAyNC0xMC0xOCAwMDowMDowMCBVVEMgdG8gMjAy
NC0xMC0xOSAwMDowMDowMCBVVEMuPC8gZGl2PjxiciAvPjxiciAvPllvdSdyZSByZWNlaXZpbmcg
dGhpcyBlbWFpbCBiZWNhdXNlIHlvdSBoYXZlIGluY2x1ZGVkIHlvdXIgZW1haWwgYWRkcmVzcyBp
biB0aGUgJ3J1YScgdGFnIG9mIHlvdXIgRE1BUkMgcmVjb3JkIGluIEROUyBmb3IgZXhhbXBsZS5j
b20uIFBsZWFzZSByZW1vdmUgeW91ciBlbWFpbCBhZGRyZXNzIGZyb20gdGhlICdydWEnIHRhZyBp
ZiB5b3UgZG9uJ3Qgd2FudCB0byByZWNlaXZlIHRoaXMgZW1haWwuPGJyIC8+PGJyIC8+PGRpdiBz
dHlsZSA9ImZvbnQtZmFtaWx5OlNlZ29lIFVJOyBmb250LXNpemU6MTJweDsgY29sb3I6IzY2NjY2
NjsiPlBsZWFzZSBkbyBub3QgcmVzcG9uZCB0byB0aGlzIGUtbWFpbC4gVGhpcyBtYWlsYm94IGlz
IG5vdCBtb25pdG9yZWQgYW5kIHlvdSB3aWxsIG5vdCByZWNlaXZlIGEgcmVzcG9uc2UuIEZvciBh
bnkgZmVlZGJhY2svc3VnZ2VzdGlvbnMsIGtpbmRseSBtYWlsIHRvIGRtYXJjcmVwb3J0ZmVlZGJh
Y2tAbWljcm9zb2Z0LmNvbS48YnIgLz48YnIgLz5NaWNyb3NvZnQgcmVzcGVjdHMgeW91ciBwcml2
YWN5LiBSZXZpZXcgb3VyIE9ubGluZSBTZXJ2aWNlcyA8YSBocmVmID0iaHR0cHM6Ly9wcml2YWN5
Lm1pY3Jvc29mdC5jb20vZW4tdXMvcHJpdmFjeXN0YXRlbWVudCI+UHJpdmFjeSBTdGF0ZW1lbnQ8
L2E+LjxiciAvPk9uZSBNaWNyb3NvZnQgV2F5LCBSZWRtb25kLCBXQSwgVVNBIDk4MDUyLjwvIGRp
diA+
--_av_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_--

--_rv_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_--

--_mpm_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_
Content-Type: application/gzip
Content-Transfer-Encoding: base64
Content-ID: <93129a97-7f1b-440b-9abe-5591e0955933>
Content-Description: protection.outlook.com!example.com!1729209600!1729296000.xml.gz
Content-Disposition: attachment; filename="protection.outlook.com!example.com!1729209600!1729296000.xml.gz";

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

--_mpm_a4bcd9a515b44b9d8eceb05d7333675fpiotk5m200exchangecorpm_--
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
