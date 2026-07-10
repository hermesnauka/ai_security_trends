using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SharpGuard.Api.Auth;
using SharpGuard.Api.Data;
using SharpGuard.Api.Dtos;
using SharpGuard.Api.Endpoints;

var builder = WebApplication.CreateBuilder(args);

// Flat env-var names (DB_HOST, JWT_SECRET, ...) instead of ASP.NET Core's
// Section__Key convention, to match every other sibling app's
// scripts/local-dev-up.sh in this repo, which exports these exact names.
string Env(string name, string fallback) =>
    Environment.GetEnvironmentVariable(name) is { Length: > 0 } v ? v : fallback;

var httpPort = Env("HTTP_PORT", "8080");
builder.WebHost.UseUrls($"http://0.0.0.0:{httpPort}");

var dbHost = Env("DB_HOST", "127.0.0.1");
var dbPort = Env("DB_PORT", "5432");
var dbName = Env("DB_NAME", "sharpguard");
var dbUser = Env("DB_USER", "sharpguard");

// No hardcoded fallback for the password specifically (unlike host/port/
// name/user above, which are harmless conventional defaults) - app08's
// sibling shipped a hardcoded DB/JWT/admin-hash fallback that silently
// activates whenever the env var is unset or blank. Fail fast instead.
var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");
if (string.IsNullOrWhiteSpace(dbPassword))
{
    throw new InvalidOperationException(
        "DB_PASSWORD is not set. Copy .env.example to .env and fill in every value before running.");
}
var connectionString =
    $"Host={dbHost};Port={dbPort};Database={dbName};Username={dbUser};Password={dbPassword}";

// JWT_SECRET has no hardcoded fallback on purpose - app08's sibling shipped
// a hardcoded dev default that silently activates whenever the env var is
// unset or blank, and nobody documented the matching plaintext password for
// its seeded hash. Fail fast instead.
var jwtSecret = Environment.GetEnvironmentVariable("JWT_SECRET");
if (string.IsNullOrWhiteSpace(jwtSecret))
{
    throw new InvalidOperationException(
        "JWT_SECRET is not set. Copy .env.example to .env and fill in every value before running.");
}
var jwtExpirationMinutes = int.TryParse(Environment.GetEnvironmentVariable("JWT_EXPIRATION_MINUTES"), out var m) ? m : 60;

var adminUsername = Environment.GetEnvironmentVariable("ADMIN_USERNAME");
var adminPasswordHash = Environment.GetEnvironmentVariable("ADMIN_PASSWORD_HASH");
if (string.IsNullOrWhiteSpace(adminUsername) || string.IsNullOrWhiteSpace(adminPasswordHash))
{
    throw new InvalidOperationException(
        "ADMIN_USERNAME / ADMIN_PASSWORD_HASH are not set. Copy .env.example to .env and fill in every value before running.");
}

builder.Configuration["Jwt:Secret"] = jwtSecret;
builder.Configuration["Jwt:ExpirationMinutes"] = jwtExpirationMinutes.ToString();
builder.Configuration["Admin:Username"] = adminUsername;
builder.Configuration["Admin:PasswordHash"] = adminPasswordHash;

builder.Services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connectionString));
builder.Services.AddSingleton<JwtTokenService>();

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
});

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
        };
    });
builder.Services.AddAuthorization();

// Wildcard origin, no credentials - this is a bearer-token API (no cookies),
// same reasoning as app08's sibling. HTTP_PORT below matches the pattern
// every other app's local-dev-up.sh / .env.example expects.
const string CorsPolicy = "AllowAny";
builder.Services.AddCors(options =>
{
    options.AddPolicy(CorsPolicy, policy => policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

app.UseExceptionHandler(exceptionApp => exceptionApp.Run(async context =>
{
    context.Response.ContentType = "application/json";
    context.Response.StatusCode = StatusCodes.Status500InternalServerError;
    await context.Response.WriteAsJsonAsync(
        ErrorResponse.Create(500, "Internal Server Error", "Internal server error"));
}));

app.UseCors(CorsPolicy);
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok(new { status = "UP" }));

app.MapAuthEndpoints();
app.MapFrameworkEndpoints();
app.MapThreatEndpoints();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
    await SeedData.EnsureSeededAsync(db);
}

app.Run();
