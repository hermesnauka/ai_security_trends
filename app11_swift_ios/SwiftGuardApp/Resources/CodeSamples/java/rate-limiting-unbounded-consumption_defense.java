// SECURE pattern
private final RateLimiter rateLimiter = RateLimiter.of("chat", RateLimiterConfig.custom()
    .limitForPeriod(20).limitRefreshPeriod(Duration.ofMinutes(1)).build());

@PostMapping("/chat")
public ChatResponse chat(@RequestBody ChatRequest req) {
    // WHY: bounding calls per refresh window prevents a single client from driving unbounded LLM spend
    return RateLimiter.decorateSupplier(rateLimiter, () -> new ChatResponse(chatClient.call(req.message()))).get();
}
