// SECURE pattern
var limiters sync.Map // userID -> *rate.Limiter

func limiterFor(userID string) *rate.Limiter {
    l, _ := limiters.LoadOrStore(userID, rate.NewLimiter(rate.Every(3*time.Second), 20))
    return l.(*rate.Limiter)
}

func chatHandler(w http.ResponseWriter, r *http.Request) {
    userID := r.Header.Get("X-User-Id")
    // WHY: a per-user token bucket bounds LLM call volume, directly mitigating LLM10:2025 Unbounded Consumption
    if !limiterFor(userID).Allow() {
        http.Error(w, "rate limited", http.StatusTooManyRequests)
        return
    }
    var req ChatRequest
    json.NewDecoder(r.Body).Decode(&req)
    reply, _ := llmClient.Complete(r.Context(), req.Message)
    json.NewEncoder(w).Encode(ChatResponse{Reply: reply})
}
