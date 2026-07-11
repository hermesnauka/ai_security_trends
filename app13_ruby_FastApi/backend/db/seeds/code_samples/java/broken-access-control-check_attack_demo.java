// VULNERABLE — do not use in production
@GetMapping("/invoices/{id}")
public Invoice getInvoice(@PathVariable long id) {
    return invoiceRepository.findById(id).orElseThrow();
}
