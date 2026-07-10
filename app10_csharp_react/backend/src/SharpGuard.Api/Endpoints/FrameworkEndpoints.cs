using Microsoft.EntityFrameworkCore;
using SharpGuard.Api.Data;
using SharpGuard.Api.Dtos;

namespace SharpGuard.Api.Endpoints;

public static class FrameworkEndpoints
{
    public static void MapFrameworkEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/api/v1/frameworks", async (AppDbContext db) =>
        {
            var frameworks = await db.Frameworks.OrderBy(f => f.Name).ToListAsync();
            return Results.Ok(frameworks.Select(FrameworkResponse.From).ToList());
        });

        app.MapGet("/api/v1/frameworks/{code}", async (string code, AppDbContext db) =>
        {
            var framework = await db.Frameworks.SingleOrDefaultAsync(f => f.Code == code);
            return framework is null
                ? ErrorResults.NotFound($"Framework not found: {code}")
                : Results.Ok(FrameworkResponse.From(framework));
        });
    }
}
