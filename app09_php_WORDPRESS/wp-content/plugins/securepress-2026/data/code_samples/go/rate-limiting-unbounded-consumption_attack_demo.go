// VULNERABLE — do not use in production
func chatHandler(w http.ResponseWriter, r *http.Request) {
    var req ChatRequest
    json.NewDecoder(r.Body).Decode(&req)
    reply, _ := llmClient.Complete(r.Context(), req.Message)
    json.NewEncoder(w).Encode(ChatResponse{Reply: reply})
}
