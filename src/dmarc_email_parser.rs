use std::io::{Cursor, Read, Seek};
use std::path::Path;
use flate2::read::GzDecoder;
use mail_parser::{Message, MessageParser, MimeHeaders};
use regex::Regex;
use zip::ZipArchive;

/// Read an email file and extract its DMARC reports as a vector of strings
pub fn extract_reports_from_email(email_body: String) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    // Parse the email:
    let message = MessageParser::default().parse(email_body.as_str()).unwrap();

    // Extract the attachments from the email:
    let mut attachments = Vec::new();
    extract_attachments(&message, &mut attachments);

    // Loop over all the attachments:
    let mut dmarc_reports = Vec::new();
    for (filename, attachment) in attachments {

        // Extract the extension of the file:
        let path = Path::new(&filename);
        let extension = path.extension().and_then(std::ffi::OsStr::to_str);

        // Decompress the file:
        match extension {
            Some("gz") => {
                let mut d = GzDecoder::new(attachment);
                let mut s = String::new();
                d.read_to_string(&mut s).unwrap();
                dmarc_reports.extend([s]);
            }
            Some("zip") => {
                let cu = Cursor::new(attachment);
                let s = read_zip_file(cu)?;
                dmarc_reports.extend(s);
            }
            _ => {}
        }
    }

    Ok(dmarc_reports)
}

/// Extract the DMARC attachments from an email
fn extract_attachments<'a>(message: &'a Message<'a>, attachments: &mut Vec<(String, &'a [u8])>) {
    // Check the format of DMARC report attachments
    // Example: protection.example.net.com!example.com!1728518400!1728604800.xml.gz
    let re = Regex::new(r"^[^!]+![^!]+!\d+!\d+\.(xml.gz|zip)$").unwrap();

    for attachment in message.attachments() {
        if !attachment.is_message() {
            let filename = attachment.attachment_name().unwrap_or("Untitled").to_string();
            if !re.is_match(filename.as_str()) {
                // The filename doesn't match our expect format, let's ignore it:
                continue;
            }
            attachments.push((filename, attachment.contents()));
        } else {
            // This part of the message is a group of message, let's recurse:
            extract_attachments(attachment.message().unwrap(), attachments);
        }
    }
}

/// Return the files contained in a zip file
fn read_zip_file(file_content: impl Read + Seek) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let mut zip = ZipArchive::new(file_content)?;
    let mut results: Vec<String> = Vec::new();

    // Iterate over all the files in the archive
    for i in 0..zip.len() {
        let mut file = zip.by_index(i)?;

        // Check if the file is not a directory
        if file.is_file() {
            // Read file content as a string
            let mut content = String::new();
            file.read_to_string(&mut content)?;
            results.push(content);
        }
    }

    Ok(results)
}

#[cfg(test)]
mod tests {
    use std::error::Error;
    use std::fs;
    use crate::dmarc_email_parser;

    #[test]
    fn it_parse_email_with_zip() -> Result<(), Box<dyn Error>> {
        let reference_report: String = fs::read_to_string("tests/dmarc_emails/google.com!example.net!1728777600!1728863999.xml")?;
        let reports = dmarc_email_parser::extract_reports_from_email(fs::read_to_string("tests/dmarc_emails/report-with-zip.eml").unwrap())?;
        assert_eq!(reports.len(), 1);
        assert_eq!(reports[0], reference_report);
        Ok(())
    }

    #[test]
    fn it_parse_email_with_gzip() -> Result<(), Box<dyn Error>> {
        let reference_report: String = fs::read_to_string("tests/dmarc_emails/google.com!example.net!1728777600!1728863999.xml")?;
        let reports = dmarc_email_parser::extract_reports_from_email(fs::read_to_string("tests/dmarc_emails/report-with-gz.eml").unwrap())?;
        assert_eq!(reports.len(), 1);
        assert_eq!(reports[0], reference_report);
        Ok(())
    }

    #[test]
    fn it_parse_unrelated_email() -> Result<(), Box<dyn Error>> {
        let reports = dmarc_email_parser::extract_reports_from_email(fs::read_to_string("tests/dmarc_emails/not-a-dmarc-report.eml").unwrap())?;
        assert_eq!(reports.len(), 0);
        Ok(())
    }

    #[test]
    fn it_parse_email_with_unreadable_zip() -> Result<(), Box<dyn Error>> {
        // This email has a zip attachment that cannot be read:
        let result = dmarc_email_parser::extract_reports_from_email(fs::read_to_string("tests/dmarc_emails/report-with-unreadable-zip.eml").unwrap());
        assert!(result.is_err());
        Ok(())
    }
}
