namespace SharpGuard.Api.Dtos;

// {timestamp, status, error, message} - the shape app01's ApiExceptionHandler
// (and Spring Boot's default error handling) actually produces. `error` is
// the HTTP reason phrase (e.g. "Not Found"), not a machine-readable code.
public record ErrorResponse(string Timestamp, int Status, string Error, string Message)
{
    public static ErrorResponse Create(int status, string error, string message) =>
        new(DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"), status, error, message);
}
