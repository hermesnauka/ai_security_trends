// SECURE pattern
func getInvoice(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    userID := auth.UserIDFromContext(r.Context())
    // WHY: the repository query itself scopes by owner, so a mismatched id returns "not found", not someone else's data
    invoice, err := repo.FindByIDAndOwner(r.Context(), id, userID)
    if err != nil {
        http.Error(w, "not found", http.StatusNotFound)
        return
    }
    json.NewEncoder(w).Encode(invoice)
}
