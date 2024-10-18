use crate::dmarc_report_model::{AuthResultType, DKIMResultType, Feedback, RecordType, SPFResultType};

pub struct DMARCRecordEvaluationResult {
    pub result: bool,
    pub syslog_message: String,
}

/// Check an auth-result-type object and return true if all its policy evaluations are "pass":
fn check_auth_results(auth_results: &AuthResultType) -> bool {

    // Check the SPF fields:
    for spf in &auth_results.spf {
        if !matches!(spf.result,  SPFResultType::Pass) {
            return false;
        }
    }

    // Check the DKIM fields:
    if auth_results.dkim.is_some() {
        for dkim in auth_results.dkim.as_ref().unwrap() {
            if !matches!(dkim.result,  DKIMResultType::Pass) {
                return false;
            }
        }
    }

    // If we couldn't find any fails, we're happy:
    true
}

/// Check a DMARC report for failures and prepare a message to write to the log files
pub fn check_dmarc_record(document: &Feedback, record: &RecordType) -> DMARCRecordEvaluationResult {
    if check_auth_results(&record.auth_results) {
        DMARCRecordEvaluationResult {
            result: true,
            syslog_message: format!("DMARC report for {}[{}] matched {} messages \
            between {} and {}, and doesn't report any failure.",
                                    document.policy_published.domain, record.row.source_ip,
                                    record.row.count,
                                    document.report_metadata.date_range.begin.unwrap(),
                                    document.report_metadata.date_range.end.unwrap())
        }
    } else {
        DMARCRecordEvaluationResult {
            result: false,
            syslog_message: format!("DMARC report for {}[{}] matched {} messages \
            between {} and {}, has failures!.",
                                    document.policy_published.domain, record.row.source_ip,
                                    record.row.count,
                                    document.report_metadata.date_range.begin.unwrap(),
                                    document.report_metadata.date_range.end.unwrap())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::error::Error;
    use serde_xml_rs::from_str;

    #[test]
    fn it_good_dmarc_report() -> Result<(), Box<dyn Error>> {
        let message: String = fs::read_to_string("tests/dmarc_reports/correct_dmarc_report.xml")?;
        let document: Feedback = from_str(message.as_str()).unwrap();
        let result = check_dmarc_record(&document, &document.record[0]);
        assert_eq!(result.result, true);
        assert_eq!(result.syslog_message, "DMARC report for example.com[203.0.113.42] matched 1 messages between 2024-10-10 00:00:00 UTC and 2024-10-11 00:00:00 UTC, and doesn't report any failure.");
        Ok(())
    }

    #[test]
    fn it_failing_dmarc_report() -> Result<(), Box<dyn Error>> {
        let message: String = fs::read_to_string("tests/dmarc_reports/failing_dmarc_report.xml")?;
        let document: Feedback = from_str(message.as_str()).unwrap();
        let result = check_dmarc_record(&document, &document.record[0]);
        assert_eq!(result.result, false);
        assert_eq!(result.syslog_message, "DMARC report for example.com[203.0.113.51] matched 1 messages between 2024-10-10 00:00:00 UTC and 2024-10-11 00:00:00 UTC, has failures!.");
        Ok(())
    }

    #[test]
    fn it_read_garbage_bytes() -> Result<(), Box<dyn Error>> {
        // Read some garbage and check that the XML parser returns an error:
        let message: String = fs::read_to_string("tests/dmarc_reports/garbage_string.xml")?;
        let result: Result<Feedback, _> = from_str(message.as_str());
        assert!(result.is_err());
        Ok(())
    }
}
