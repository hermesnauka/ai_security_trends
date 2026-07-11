// SECURE pattern
@GetMapping("/invoices/{id}")
public Invoice getInvoice(@PathVariable long id, @AuthenticationPrincipal AppUser user) {
    // WHY: ownership is enforced in the query itself, not checked after the fact in application code
    return invoiceRepository.findByIdAndOwnerId(id, user.getId())
        .orElseThrow(() -> new AccessDeniedException("not your invoice"));
}
