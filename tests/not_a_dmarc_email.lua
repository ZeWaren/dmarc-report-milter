local utils = require("tests.utils")

local socket = "unix:/tmp/dmarc-report-milter-test.sock"

conn = mt.connect(socket)
assert(conn, "could not open connection")

local mail_text=[=[
From: jambon@example.com
To: poulet@example.com
Subject: This is an email
Date: Sun, 8 Jan 2017 20:37:44 +0200

You are a sausage!
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
assert(mt.getreply(conn) == SMFIR_CONTINUE)

local err = mt.disconnect(conn)
assert(err == nil, err)
