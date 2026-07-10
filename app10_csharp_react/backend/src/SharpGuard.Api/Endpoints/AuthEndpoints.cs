using SharpGuard.Api.Auth;
using SharpGuard.Api.Dtos;

namespace SharpGuard.Api.Endpoints;

// Dev-only single-admin login: no user table exists yet (Phase 1 scope has no
// admin CRUD either). Credentials come from config, never hardcoded in
// source - see appsettings/env vars Admin:Username / Admin:PasswordHash.
// Mirrors app01's AuthController exactly, including the error message text.
public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/v1/auth/login", (LoginRequest? request, IConfiguration config, JwtTokenService jwt) =>
        {
            if (request is null || string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
            {
                return ErrorResults.BadRequest("Request body must be JSON");
            }

            var adminUsername = config["Admin:Username"]
                ?? throw new InvalidOperationException("Admin:Username is not configured");
            var adminPasswordHash = config["Admin:PasswordHash"]
                ?? throw new InvalidOperationException("Admin:PasswordHash is not configured");

            bool usernameOk = adminUsername == request.Username;
            bool passwordOk = usernameOk && BCrypt.Net.BCrypt.Verify(request.Password, adminPasswordHash);

            if (!usernameOk || !passwordOk)
            {
                return ErrorResults.Unauthorized("Invalid username or password");
            }

            var token = jwt.GenerateToken(adminUsername, "ADMIN");
            return Results.Ok(LoginResponse.Bearer(token, "ADMIN"));
        });
    }
}
