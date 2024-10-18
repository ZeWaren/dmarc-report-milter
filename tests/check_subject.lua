local socket = "unix:/tmp/dmarc-report-milter-test.sock"

--mt.startfilter("target/debug/dmarc-report-milter", "-s", socket)
--mt.sleep(1)

conn = mt.connect(socket)
assert(conn, "could not open connection")

local err = mt.header(conn, "Subject", "My family vacations")
assert(err == nil, err)
assert(mt.getreply(conn) == SMFIR_ACCEPT)

local err = mt.header(conn, "Subject", "Report Domain: example.com Submitter: mail.receiver.example Report-ID: <2002.02.15.1>")
assert(err == nil, err)
assert(mt.getreply(conn) == SMFIR_CONTINUE)

local err = mt.disconnect(conn)
assert(err == nil, err)
