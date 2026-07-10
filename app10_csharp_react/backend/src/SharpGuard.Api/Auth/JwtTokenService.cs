using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace SharpGuard.Api.Auth;

// HS256 with a shared secret - matches app01's JwtService (Keys.hmacShaKeyFor),
// the real canonical contract. Several sibling PLAN.md files assumed RS256;
// that assumption is wrong, app01 never had a key pair.
public class JwtTokenService(IConfiguration configuration)
{
    private readonly string _secret = configuration["Jwt:Secret"]
        ?? throw new InvalidOperationException("Jwt:Secret is not configured");
    private readonly int _expirationMinutes = configuration.GetValue("Jwt:ExpirationMinutes", 60);

    public string GenerateToken(string subject, string role)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var now = DateTime.UtcNow;
        var token = new JwtSecurityToken(
            claims: [new Claim(JwtRegisteredClaimNames.Sub, subject), new Claim("role", role)],
            notBefore: now,
            expires: now.AddMinutes(_expirationMinutes),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
