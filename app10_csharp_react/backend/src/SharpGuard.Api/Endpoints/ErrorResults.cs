using SharpGuard.Api.Dtos;

namespace SharpGuard.Api.Endpoints;

public static class ErrorResults
{
    public static IResult Problem(int status, string error, string message) =>
        Results.Json(ErrorResponse.Create(status, error, message), statusCode: status);

    public static IResult NotFound(string message) => Problem(404, "Not Found", message);

    public static IResult Unauthorized(string message) => Problem(401, "Unauthorized", message);

    public static IResult BadRequest(string message) => Problem(400, "Bad Request", message);
}
