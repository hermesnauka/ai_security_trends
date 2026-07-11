# VULNERABLE — do not use in production
def get_invoice(request, invoice_id):
    invoice = Invoice.objects.get(id=invoice_id)
    return JsonResponse({"total": invoice.total})
