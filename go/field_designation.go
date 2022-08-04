package main

import (
	"errors"
	"regexp"
)

type FieldPattern struct {
	ItemTitle  string `json:"item_title"`
	FieldTitle string `json:"field_title"`
	FieldType  string `json:"field_type"`
	pattern    *regexp.Regexp
}

// ref: https://github.com/vietjovi/secret-detection/
// ref: https://github.com/Skyscanner/whispers
var FIELD_PATTERNS = []FieldPattern{
	/// Generic patterns
	{
		FieldTitle: "email",
		FieldType:  "email",
		pattern:    regexp.MustCompile("[^\t\n\r \"'@]+@[^\t\n\r \"'@]+.[^\t\n\r \"'@]+"),
	},
	{
		FieldTitle: "url",
		FieldType:  "url",
		pattern:    regexp.MustCompile("https?:\\/\\/(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()!@:%_\\+.~#?&\\/\\/=]*)"),
	},
	{
		FieldTitle: "credit card",
		FieldType:  "text",
		pattern:    regexp.MustCompile("(?:4[0-9]{12}(?:[0-9]{3})?|[25][1-7][0-9]{14}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\\d{3})\\d{11})"),
	},

	/// Site/service specific patterns

	// TODO positive lookahead is not supported in Go regex, so these two patterns don't work
	// {
	// 	ItemTitle:  "AWS",
	// 	FieldTitle: "access key id",
	// 	FieldType:  "text",
	// 	pattern:    regexp.MustCompile("(?=.*[A-Z])(?=.*[0-9])A(AG|CC|GP|ID|IP|KI|NP|NV|PK|RO|SC|SI)A[A-Z0-9]{16}"),
	// },
	// {
	// 	ItemTitle:  "AWS",
	// 	FieldTitle: "session token",
	// 	FieldType:  "concealed",
	// 	pattern:    regexp.MustCompile("(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])[A-Za-z0-9+/]{270,450}"),
	// },
	{
		ItemTitle:  "Facebook",
		FieldTitle: "access token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("EAA[0-9a-zA-Z]{160,180}ZDZD"),
	},
	{
		ItemTitle:  "Google",
		FieldTitle: "api key",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("AIza[0-9A-Za-z-_]{35}"),
	},
	{
		ItemTitle:  "GCP",
		FieldTitle: "client id",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("[0-9]+-[0-9A-Za-z_]{32}.apps.googleusercontent.com"),
	},
	{
		ItemTitle:  "Mailchimp",
		FieldTitle: "api key",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("[0-9a-f]{32}-us[0-9]{1,2}"),
	},
	{
		ItemTitle:  "PayPal Braintree",
		FieldTitle: "access token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("access_token\\$(production|sandbox)\\[0-9a-z]{16}\\$[0-9a-f]{32}"),
	},
	{
		ItemTitle:  "PayPal Braintree",
		FieldTitle: "client id",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("client_id\\$(production|sandbox)\\$[0-9a-z]{16}"),
	},
	{
		ItemTitle:  "PayPal Braintree",
		FieldTitle: "client secret",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("client_secret\\$(production|sandbox)\\$[0-9a-z]{32}"),
	},
	{
		ItemTitle:  "PayPal Braintree",
		FieldTitle: "tokenization key",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("(production|sandbox)_[0-9a-z]{8}_[0-9a-z]{16}"),
	},
	{
		ItemTitle:  "SendGrid",
		FieldTitle: "api key",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("SG.[0-9A-Za-z-._]{66}"),
	},
	{
		ItemTitle:  "Slack",
		FieldTitle: "api token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("xox[p|b|o|a]-[0-9]{12}-[0-9]{12,13}-[a-zA-Z0-9]{23,32}"),
	},
	{
		ItemTitle:  "Slack",
		FieldTitle: "webhook",
		FieldType:  "url",
		pattern:    regexp.MustCompile("https:\\/\\/hooks.slack.com\\/services\\/[A-Z0-9]{9}\\/[A-Z0-9]{9,11}\\/[a-zA-Z0-9]+"),
	},
	{
		ItemTitle:  "DigitalOcean",
		FieldTitle: "access token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("dop_v1_[a-z0-9]{64}"),
	},
	{
		ItemTitle:  "Supabase",
		FieldTitle: "api-key",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("sbp_[a-zA-Z0-9]{40}"),
	},
	{
		ItemTitle:  "Typeform",
		FieldTitle: "personal access token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("tfp_[a-zA-Z0-9]{44}_[a-zA-Z0-9]{14}"),
	},
	{
		ItemTitle:  "Stripe",
		FieldTitle: "publishable key",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("pk_(test|live)_[0-9a-zA-Z]{24,99}"),
	},
	{
		ItemTitle:  "Stripe",
		FieldTitle: "secret key",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("sk_(test|live)_[0-9a-zA-Z]{24,99}"),
	},
	{
		ItemTitle:  "Twilio",
		FieldTitle: "api key",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("SK[0-9a-fA-F]{32}"),
	},
	{
		ItemTitle:  "GitHub",
		FieldTitle: "token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("(gh[pous]_[a-zA-Z0-9]{36}|ghr_[a-zA-Z0-9]{76})"),
	},
	{
		ItemTitle:  "HubSpot",
		FieldTitle: "webhook",
		FieldType:  "url",
		pattern:    regexp.MustCompile("https://api.hubapi.com/webhooks/v1/[a-z0-9]+/"),
	},
	{
		ItemTitle:  "HubSpot",
		FieldTitle: "private app token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("pat-(na|eu)1-[a-fA-F\\d]{4}(?:[a-fA-F\\d]{4}-){4}[a-fA-F\\d]{12}"),
	},
	{
		ItemTitle:  "SSH Key",
		FieldTitle: "private key",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("[-]{3,}BEGIN (RSA|DSA|EC|OPENSSH|PRIVATE)? ?(PRIVATE)? KEY[-]{3,}[\\D\\d\\s]*[-]{3,}END (RSA|DSA|EC|OPENSSH|PRIVATE)? ?(PRIVATE)? KEY[-]{3,}(\\n)?"),
	},
	{
		FieldTitle: "uuid",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("[a-fA-F\\d]{4}(?:[a-fA-F\\d]{4}-){4}[a-fA-F\\d]{12}"),
	},
	{
		ItemTitle:  "Amazon MWS",
		FieldTitle: "auth token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("amzn.mws.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"),
	},
	{
		ItemTitle:  "Google",
		FieldTitle: "oauth token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("ya29.[0-9A-Za-z-_]+"),
	},
	{
		ItemTitle:  "Mailgun",
		FieldTitle: "api key",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("key-[0-9a-zA-Z]{32}"),
	},
	{
		ItemTitle:  "Square",
		FieldTitle: "access token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("sq0atp-[0-9A-Za-z-_]{22}"),
	},
	{
		ItemTitle:  "Square",
		FieldTitle: "oauth token",
		FieldType:  "concealed",
		pattern:    regexp.MustCompile("sq0csp-[0-9A-Za-z-_]{43}"),
	},
	{
		ItemTitle:  "Twilio",
		FieldTitle: "webhook",
		FieldType:  "url",
		pattern:    regexp.MustCompile("https://chat.twilio.com/v2/Services/[A-Z0-9]{32}"),
	},
}

func GetFieldDesignation(value string) (FieldPattern, error) {
	for _, fieldPattern := range FIELD_PATTERNS {
		if fieldPattern.pattern.MatchString(value) {
			return fieldPattern, nil
		}
	}

	return FieldPattern{}, errors.New("None found")
}
