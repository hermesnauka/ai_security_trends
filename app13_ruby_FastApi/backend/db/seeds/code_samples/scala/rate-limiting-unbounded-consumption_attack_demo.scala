// VULNERABLE — do not use in production
def chat(req: ChatRequest): Task[ChatResponse] =
  llmClient.complete(req.message).map(ChatResponse(_))
