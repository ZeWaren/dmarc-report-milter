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
Content-Type: application/zip;
  	name="google.com!example.net!1728777600!1728863999.zip"
Content-Disposition: attachment;
  	filename="google.com!example.net!1728777600!1728863999.zip"
Content-Transfer-Encoding: base64

UEsDBBQAAAAIAMtQUlkZ5L0q8QEAAOkEAAAwAAAAZ29vZ2xlLmNvbSFleGFtcGxlLm5ldCEx
NzI4Nzc3NjAwITE3Mjg4NjM5OTkueG1srVTBcpswEL13pv/g8d3I2ARwZ6P01C9oz4wsFqwE
JI0kEufvK2wZKYlneumJ5e3u231PAng6j8PqFY0VSj6u82y7XqHkqhWyf1z/+f1rU69XT/T7
N+gQ2yPjLz5ercCgVsY1IzrWMscuoIeV6RvJRqS9Uv2AGVcjkAUMRTgyMVCpPMfwvmlHZvjG
Tnom/Jn2XetuTWdnWMOVdIy7RshO0ZNz2v4gJPRmsZcwwqR9Q0N2RVk+1Fsgd/oDc5AiWpqX
RZHneV2U9b7a11VRVg9AYj40eMHYGCb7myKPHbEXkubVrq6qqtz6gVdkKUDZXtJ1uT8cDn4f
ufCRT4RA7rkLWg2Cvzd6Og7CnjCuo7xPkuKZjdrLl+iABCxUsPZFjNQAuQY31OruAs7PgGlq
8Bm5Z9A3yEbMLqDmjuazyjkImIyFUgchd3f2jnNllv2Neos2WTUZjo3QdLfdZ9ssz/dZsQMS
8aWUq0n6LYBcgwUPM/GVDZM3tl0ys1fCamWFE0r6CygRSIqkhbNRmlkLJPEsGNKFTDQu0fp5
LpAoEESL0olO+O8tdp6QtWiazqjx4ymmiRvZVwZgkzs1Bu00uIT189r/vCaXqitN0BdeUu04
+ANWhj6z8agkkAWIPnwYDKlH/2WL1HYgX7QDWW4XkOSf9RdQSwECHwAUAAAACADLUFJZGeS9
KvEBAADpBAAAMAAkAAAAAAAAACAAAAAAAAAAZ29vZ2xlLmNvbSFleGFtcGxlLm5ldCExNzI4
Nzc3NjAwITE3Mjg4NjM5OTkueG1sCgAgAAAAAAABABgA248YnzQh2wFSX8i3NCHbASgbsIQ0
IdsBUEsFBgAAAAABAAEAggAAAD8CAAAAAA==
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
