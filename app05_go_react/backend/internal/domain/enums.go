package domain

// Severity - see PLAN.md section 5.1.
type Severity string

const (
	SeverityCritical Severity = "CRITICAL"
	SeverityHigh     Severity = "HIGH"
	SeverityMedium   Severity = "MEDIUM"
	SeverityLow      Severity = "LOW"
	SeverityInfo     Severity = "INFO"
)

// StrideCategory - one of S, T, R, I, D, E.
type StrideCategory string

const (
	StrideSpoofing              StrideCategory = "S"
	StrideTampering             StrideCategory = "T"
	StrideRepudiation           StrideCategory = "R"
	StrideInformationDisclosure StrideCategory = "I"
	StrideDenialOfService       StrideCategory = "D"
	StrideElevationOfPrivilege  StrideCategory = "E"
)
