namespace SharpGuard.Api.Dtos;

// Mirrors Spring Data's Page<T> envelope (the contract of record's shape),
// not any .NET-native paging convention.
public record PageResponse<T>(
    List<T> Content,
    long TotalElements,
    int TotalPages,
    int Number,
    int Size)
{
    public static PageResponse<T> Of(List<T> content, long totalElements, int page, int size)
    {
        var totalPages = size > 0 ? (int)Math.Ceiling(totalElements / (double)size) : 0;
        return new PageResponse<T>(content, totalElements, totalPages, page, size);
    }
}
