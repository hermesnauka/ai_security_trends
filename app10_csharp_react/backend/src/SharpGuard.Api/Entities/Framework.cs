namespace SharpGuard.Api.Entities;

public class Framework
{
    public Guid Id { get; set; }
    public required string Code { get; set; }
    public required string Name { get; set; }
    public required string Version { get; set; }
    public string? Description { get; set; }
    public string? ReferenceUrl { get; set; }

    public List<Threat> Threats { get; set; } = [];
}
