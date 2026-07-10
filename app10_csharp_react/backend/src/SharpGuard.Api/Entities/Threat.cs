namespace SharpGuard.Api.Entities;

public class Threat
{
    public Guid Id { get; set; }
    public Guid FrameworkId { get; set; }
    public Framework Framework { get; set; } = null!;

    public required string Code { get; set; }
    public required string Title { get; set; }
    public Severity Severity { get; set; }
    public string? Category { get; set; }
    public string? Description { get; set; }
    public string? AttackVector { get; set; }
    public string? AttackSurface { get; set; }

    // Comma-joined TEXT columns in Postgres - same deliberate Phase-1
    // shortcut as app01's StringListConverter/StrideSetConverter, not a
    // native array/JSON column type. Kept as raw strings at the entity/query
    // layer (not List<string> via a value converter) on purpose: EF Core
    // can't translate LINQ predicates against a converted collection back to
    // SQL on the underlying scalar column, so filtering (stride/tag query
    // params) needs the raw string here - conversion to List<string> for the
    // response body happens in the DTO mapping instead (Dtos/ThreatDtos.cs).
    public string? Stride { get; set; }
    public string? CveReferences { get; set; }
    public string? Tags { get; set; }
}
