using SharpGuard.Api.Entities;

namespace SharpGuard.Api.Dtos;

public static class CommaList
{
    public static List<string> Split(string? raw) =>
        string.IsNullOrEmpty(raw)
            ? []
            : raw.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList();
}

public record ThreatSummaryResponse(
    string Id,
    string FrameworkCode,
    string Code,
    string Title,
    string Severity,
    string? Category,
    List<string> Stride,
    List<string> Tags)
{
    public static ThreatSummaryResponse From(Threat threat) => new(
        threat.Id.ToString(),
        threat.Framework.Code,
        threat.Code,
        threat.Title,
        threat.Severity.ToString(),
        threat.Category,
        CommaList.Split(threat.Stride),
        CommaList.Split(threat.Tags));
}

// Full detail view for GET /api/v1/threats/{id}. Mitigations/code samples are
// Phase 2 (data model migrated, not mapped yet) - intentionally omitted
// rather than faked as empty placeholders, matching app01's ThreatResponse.
public record ThreatResponse(
    string Id,
    string FrameworkCode,
    string FrameworkName,
    string Code,
    string Title,
    string Severity,
    string? Category,
    string? Description,
    string? AttackVector,
    string? AttackSurface,
    List<string> Stride,
    List<string> CveReferences,
    List<string> Tags)
{
    public static ThreatResponse From(Threat threat) => new(
        threat.Id.ToString(),
        threat.Framework.Code,
        threat.Framework.Name,
        threat.Code,
        threat.Title,
        threat.Severity.ToString(),
        threat.Category,
        threat.Description,
        threat.AttackVector,
        threat.AttackSurface,
        CommaList.Split(threat.Stride),
        CommaList.Split(threat.CveReferences),
        CommaList.Split(threat.Tags));
}
