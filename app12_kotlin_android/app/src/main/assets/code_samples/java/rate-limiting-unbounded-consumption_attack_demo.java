// VULNERABLE — do not use in production
@PostMapping("/chat")
public ChatResponse chat(@RequestBody ChatRequest req) {
    return new ChatResponse(chatClient.call(req.message()));
}
