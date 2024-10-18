use std::fmt::Write;
use std::process;
use clap::Parser;
use milter::{on_body, on_eom, on_header, Context, Milter, Status};
use regex::Regex;
use serde_xml_rs::from_str;
use crate::dmarc_email_parser::extract_reports_from_email;
use crate::dmarc_report_model::Feedback;
use crate::dmarc_report_process::check_dmarc_record;
extern crate syslog;
use syslog::{Facility, Formatter3164};

mod dmarc_report_model;
mod dmarc_report_process;
mod dmarc_email_parser;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
/// A milter that discards passing DMARC reports
struct Args {
    /// Socket specification for the milter to listen to.
    ///
    /// inet:port@host – an IPv4 socket OR
    /// inet6:port@host – an IPv6 socket where port is a numeric port, and host can be either a hostname or an IP address  OR
    /// {unix|local}:path – a UNIX domain socket at an absolute file system path
    #[arg(short, long, default_value = "inet:3000@localhost")]
    socket: String,
}

/// Stores the data sent part by part by the milter:
struct EmailBuffer {
    headers: String,
    body: Vec<u8>,
}

fn main() {

    let args = Args::parse();

    Milter::new(args.socket.as_str())
        .name("dmarc-report-milter")
        .on_header(header_callback)
        .on_body(body_callback)
        .on_eom(eom_callback)
        .on_abort(abort_callback)
        .run()
        .expect("milter execution failed");
}


#[on_header(header_callback)]
fn handle_header(mut context: Context<EmailBuffer>, header: &str, value: &str) -> milter::Result<Status> {

    // Initialize the context if it's empty:
    if context.data.borrow_mut().is_none() {
        let email_buffer = EmailBuffer {
            headers: String::new(),
            body: Vec::new(),
        };
        context.data.replace(email_buffer)?;
    }

    if header == "Subject" {
        // If the subject doesn't match the format of a DMARC report, we simply ignore the email,
        // and we pass it forward.
        // Reference: https://datatracker.ietf.org/doc/html/rfc7489#section-7.2.1.1
        let re = Regex::new(r"(?i)^Report Domain: .+ Submitter: .+ Report-ID: .+$").unwrap();
        if !re.is_match(value) {
            return Ok(Status::Accept)
        }
    }

    // Append the current header to the list of headers:
    write!(context.data.borrow_mut().as_mut().unwrap().headers, "{header}: {value}\r\n").expect("Can't append headers");

    Ok(Status::Continue)
}

#[on_body(body_callback)]
fn handle_body(mut context: Context<EmailBuffer>, content_chunk: &[u8]) -> milter::Result<Status> {

    context.data.borrow_mut().unwrap().body.extend_from_slice(content_chunk);

    Ok(Status::Continue)
}

#[on_eom(eom_callback)]
fn handle_eom(context: Context<EmailBuffer>) -> milter::Result<Status> {

    // Parse the data we received previously into a string:
    let mail_data = &context.data.borrow().unwrap();
    let mail_body: String = String::from_utf8_lossy(&mail_data.body).parse().unwrap();
    let mail_header = &mail_data.headers;
    let mail_string = format!("{mail_header}\r\n\r\n{mail_body}");

    // Extract the reports from the mail body:
    let report_extraction = extract_reports_from_email(mail_string);
    if report_extraction.is_err() {
        // Something went wrong => let the email continue:
        write_to_syslog(format!("Could not extract reports from email: {}", report_extraction.unwrap_err()));
        return Ok(Status::Continue);
    }

    // Parse and check the reports:
    let reports = report_extraction.unwrap();
    if reports.is_empty() {
        // No reports in the email => let the email continue:
        write_to_syslog("DMARC report email doesn't contain any reports".to_string());
        return Ok(Status::Continue);
    }
    for report in reports {
        // Parse the XML:
        let document_parsing: Result<Feedback, _> = from_str(report.as_str());
        if document_parsing.is_err() {
            // Something went wrong => let the email continue:
            write_to_syslog(format!("Could not parse DMARC XML: {}", document_parsing.unwrap_err()));
            return Ok(Status::Continue);
        }

        // Parse and check the records in the report:
        let document = document_parsing.unwrap();
        if document.record.is_empty() {
            // No record in the email => let the email continue:
            return Ok(Status::Continue);
        }
        for record in &document.record {
            let record_result = check_dmarc_record(&document, record);
            write_to_syslog(record_result.syslog_message);
            if !record_result.result {
                // The report has failures => accept the email:
                return Ok(Status::Accept);
            }
        }
    }

    // We didn't meet any failure into any of the reports, we can discard the email.
    Ok(Status::Discard)
}

#[milter::on_abort(abort_callback)]
fn handle_abort(mut ctx: Context<String>) -> milter::Result<Status> {
    let _ = ctx.data.take();
    Ok(Status::Continue)
}

/// Write a string to the mail log through syslog
fn write_to_syslog(message: String) {
    let formatter = Formatter3164 {
        facility: Facility::LOG_MAIL,
        hostname: None,
        process: "dmarc-report-milter".into(),
        pid: process::id(),
    };

    match syslog::unix(formatter) {
        Err(_) => {},
        Ok(mut writer) => {
            writer.err(message).expect("could not write message to syslog");
        }
    }
}
