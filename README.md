# DMARC reports email milter

## Introduction

This project contains a [milter](https://en.wikipedia.org/wiki/Milter) that discards DMARC email reports that report
successes. All other emails are left untouched.

Section [7.2.1.1](https://datatracker.ietf.org/doc/html/rfc7489#section-7.2.1.1) of RFC 7489 describes the email reports
that other MTAs can send you.

Example DNS configuration:

    ;; ANSWER SECTION:
    _dmarc.example.com.       1800    IN      TXT     "v=DMARC1; p=reject; rua=mailto:postmaster@example.com; ruf=mailto:postmaster@example.com; fo=1;"


In a typical report, you might see the following results:

    <auth_results>
        <dkim>
            <domain>example.com</domain>
            <selector>jambon</selector>
            <result>pass</result>
        </dkim>
        <spf>
            <domain>example.com</domain>
            <scope>mfrom</scope>
            <result>pass</result>
        </spf>
    </auth_results>

The goal of this milter is to prevent those happy reports from reaching your inbox. The email is discarded, and an entry
is sent to the server's maillog:

    Oct 18 16:11:15 mail.example.com dmarc-report-milter[732]: DMARC report for example.net[203.0.113.42] matched 1 messages between 2024-10-13 00:00:00 UTC and 2024-10-13 23:59:59 UTC, and doesn't report any failure.

## Usage

    Usage: dmarc-report-milter [OPTIONS]
    
    Options:
    -s, --socket <SOCKET>
    Socket specification for the milter to listen to.
              inet:port@host – an IPv4 socket
              inet6:port@host – an IPv6 socket where port is a numeric port, and host can be either a hostname or an IP address
              {unix|local}:path – a UNIX domain socket at an absolute file system path
              [default: inet:3000@localhost]
    
    -h, --help
    Print help (see a summary with '-h')
    
    -V, --version
    Print version

Example:

     dmarc-report-milter -s inet:3333@localhost

Postfix configuration example:

    smtpd_milters = inet:localhost:3333

## Build

The project is written using standard Rust and Cargo logic.

    cargo build

## Testing
### Unit tests
Unit tests can be run with cargo:

    cargo test

### Acceptance tests
Acceptance tests are written in Lua and use [miltertest](http://www.opendkim.org/miltertest.8.html), which is part of
`OpenDKIM`.

Start the milter:

    dmarc-report-milter --socket "unix:/tmp/dmarc-report-milter-test.sock"

Run a test with `miltertest`:

    # miltertest -v -s tests/good_report_gz.lua
    miltertest: connected to 'unix:/tmp/dmarc-report-milter-test.sock', fd 3
    miltertest: header sent on fd 3, reply 'c'
    miltertest: header sent on fd 3, reply 'c'
    miltertest: header sent on fd 3, reply 'c'
    miltertest: header sent on fd 3, reply 'c'
    miltertest: header sent on fd 3, reply 'c'
    miltertest: header sent on fd 3, reply 'c'
    miltertest: header sent on fd 3, reply 'c'
    miltertest: header sent on fd 3, reply 'c'
    miltertest: header sent on fd 3, reply 'c'
    miltertest: header sent on fd 3, reply 'c'
    miltertest: header sent on fd 3, reply 'c'
    miltertest: 706 byte(s) of body sent on fd 3, reply 'c'
    miltertest: EOM sent on fd 3, reply 'd'
    miltertest: disconnected fd 3

