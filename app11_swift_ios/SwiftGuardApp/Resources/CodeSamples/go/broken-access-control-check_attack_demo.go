// VULNERABLE — do not use in production
func getInvoice(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    invoice, _ := repo.FindByID(r.Context(), id)
    json.NewEncoder(w).Encode(invoice)
}
