// SECURE pattern
// WHY: acquiring a permit before calling the model bounds concurrent + per-window LLM spend per user
def chat(req: ChatRequest, userId: String, limiter: RateLimiter): Task[ChatResponse] =
  limiter.rateLimit(userId) {
    llmClient.complete(req.message).map(ChatResponse(_))
  }.orElseFail(TooManyRequests(userId))
