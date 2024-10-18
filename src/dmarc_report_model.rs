use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use chrono::serde::ts_seconds_option;

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "DateRangeType")]
pub struct DateRangeType {
    #[serde(with = "ts_seconds_option")]
    pub begin: Option<DateTime<Utc>>,
    #[serde(with = "ts_seconds_option")]
    pub end: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "ReportMetadataType")]
pub struct ReportMetadataType {
    pub org_name: String,
    pub email: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub extra_contact_info: Option<String>,
    pub report_id: String,
    pub date_range: DateRangeType,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<Vec<String>>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AlignmentType {
    R,
    S,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DispositionType {
    None,
    Quarantine,
    Reject,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "PolicyPublishedType")]
pub struct PolicyPublishedType {
    pub domain: String,
    pub adkim: AlignmentType,
    pub aspf: AlignmentType,
    pub p: DispositionType,
    pub sp: DispositionType,
    pub pct: i64,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DMARCResultType {
    Pass,
    Fail,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PolicyOverrideType {
    Forwarded,
    SampledOut,
    TrustedForwarder,
    MailingList,
    LocalPolicy,
    Other,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "PolicyOverrideReason")]
pub struct PolicyOverrideReason {
    pub r#type: PolicyOverrideType,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub comment: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "PolicyEvaluatedType")]
pub struct PolicyEvaluatedType {
    pub disposition: DispositionType,
    pub dkim: DMARCResultType,
    pub spf: DMARCResultType,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reason: Option<Vec<PolicyOverrideReason>>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "RowType")]
pub struct RowType {
    pub source_ip: String,
    pub count: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub policy_evaluated: Option<PolicyEvaluatedType>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "IdentifierType")]
pub struct IdentifierType {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub envelope_to: Option<String>,
    pub header_from: String,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DKIMResultType {
    None,
    Pass,
    Fail,
    Policy,
    Neutral,
    TempError,
    PermError,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "DKIMAuthResultType")]
pub struct DKIMAuthResultType {
    pub domain: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub selector: Option<String>,
    pub result: DKIMResultType,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub human_result: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SPFResultType {
    None,
    Neutral,
    Pass,
    Fail,
    SoftFail,
    TempError,
    PermError,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "SPFAuthResultType")]
pub struct SPFAuthResultType {
    pub domain: String,
    pub result: SPFResultType,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "AuthResultType")]
pub struct AuthResultType {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub dkim: Option<Vec<DKIMAuthResultType>>,
    pub spf: Vec<SPFAuthResultType>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "RecordType")]
pub struct RecordType {
    pub row: RowType,
    pub identifiers: IdentifierType,
    pub auth_results: AuthResultType,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "feedback")]
pub struct Feedback {
    pub report_metadata: ReportMetadataType,
    pub policy_published: PolicyPublishedType,
    pub record: Vec<RecordType>,
}
