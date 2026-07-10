using SharpGuard.Api.Entities;

namespace SharpGuard.Api.Dtos;

public record FrameworkResponse(
    string Id,
    string Code,
    string Name,
    string Version,
    string? Description,
    string? ReferenceUrl)
{
    public static FrameworkResponse From(Framework framework) => new(
        framework.Id.ToString(),
        framework.Code,
        framework.Name,
        framework.Version,
        framework.Description,
        framework.ReferenceUrl);
}
