namespace SharpGuard.Api.Dtos;

public record LoginRequest(string Username, string Password);

public record LoginResponse(string Token, string TokenType, string Role)
{
    public static LoginResponse Bearer(string token, string role) => new(token, "Bearer", role);
}
