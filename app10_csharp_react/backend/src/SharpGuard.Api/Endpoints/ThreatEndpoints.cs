using Microsoft.EntityFrameworkCore;
using SharpGuard.Api.Data;
using SharpGuard.Api.Dtos;
using SharpGuard.Api.Entities;

namespace SharpGuard.Api.Endpoints;

public static class ThreatEndpoints
{
    public static void MapThreatEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/api/v1/threats", async (
            string? frameworkCode, string? severity, string? stride, string? tag, string? q,
            int? page, int? size, string? sort,
            AppDbContext db) =>
        {
            int pageNum = page is >= 0 ? page.Value : 0;
            int pageSize = size is >= 1 and <= 200 ? size.Value : 20;

            IQueryable<Threat> query = db.Threats.Include(t => t.Framework);

            if (!string.IsNullOrWhiteSpace(frameworkCode))
                query = query.Where(t => t.Framework.Code == frameworkCode);

            if (!string.IsNullOrWhiteSpace(severity))
            {
                // An unparseable severity matches nothing rather than erroring -
                // app01's Java equivalent (Severity.valueOf) actually throws on
                // bad input here (an accident of the reference impl, not
                // something the contract requires); this is deliberately more
                // forgiving instead of reproducing that crash.
                query = Enum.TryParse<Severity>(severity, ignoreCase: true, out var sev)
                    ? query.Where(t => t.Severity == sev)
                    : query.Where(_ => false);
            }

            if (!string.IsNullOrWhiteSpace(stride))
                query = query.Where(t => t.Stride != null && t.Stride.Contains(stride.ToUpperInvariant()));

            if (!string.IsNullOrWhiteSpace(tag))
                query = query.Where(t => t.Tags != null && t.Tags.ToLower().Contains(tag.ToLower()));

            if (!string.IsNullOrWhiteSpace(q))
            {
                var pattern = q.ToLower();
                query = query.Where(t =>
                    t.Title.ToLower().Contains(pattern) ||
                    (t.Description != null && t.Description.ToLower().Contains(pattern)));
            }

            var totalElements = await query.LongCountAsync();
            query = ApplySort(query, sort);

            var threats = await query
                .Skip(pageNum * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var content = threats.Select(ThreatSummaryResponse.From).ToList();
            return Results.Ok(PageResponse<ThreatSummaryResponse>.Of(content, totalElements, pageNum, pageSize));
        });

        app.MapGet("/api/v1/threats/{id:guid}", async (Guid id, AppDbContext db) =>
        {
            var threat = await db.Threats.Include(t => t.Framework).SingleOrDefaultAsync(t => t.Id == id);
            return threat is null
                ? ErrorResults.NotFound($"Threat not found: {id}")
                : Results.Ok(ThreatResponse.From(threat));
        });
    }

    // Allowlist of sortable fields, same reasoning as app08's C++ sibling:
    // `sort` is user input, and unlike a value, a column/property choice
    // can't be parameterized - it has to be resolved through a fixed set of
    // known-safe options instead. Unknown field/direction falls back to the
    // default order rather than erroring, same as an unparseable severity.
    private static IQueryable<Threat> ApplySort(IQueryable<Threat> query, string? sort)
    {
        string field = "severity";
        bool descending = false;

        if (!string.IsNullOrWhiteSpace(sort))
        {
            var parts = sort.Split(',', 2);
            var candidateField = parts[0].Trim().ToLowerInvariant();
            var candidateDir = parts.Length > 1 ? parts[1].Trim().ToLowerInvariant() : "asc";

            if (candidateDir is "asc" or "desc" &&
                candidateField is "id" or "code" or "title" or "severity" or "category")
            {
                field = candidateField;
                descending = candidateDir == "desc";
            }
        }

        IOrderedQueryable<Threat> ordered = field switch
        {
            "id" => descending ? query.OrderByDescending(t => t.Id) : query.OrderBy(t => t.Id),
            "code" => descending ? query.OrderByDescending(t => t.Code) : query.OrderBy(t => t.Code),
            "title" => descending ? query.OrderByDescending(t => t.Title) : query.OrderBy(t => t.Title),
            "category" => descending ? query.OrderByDescending(t => t.Category) : query.OrderBy(t => t.Category),
            _ => descending ? query.OrderByDescending(t => t.Severity) : query.OrderBy(t => t.Severity),
        };

        return ordered.ThenBy(t => t.Code);
    }
}
