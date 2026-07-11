# SECURE pattern
def get_invoice(request, invoice_id):
    # WHY: the owner check happens server-side against the authenticated user, not the client-supplied id alone
    invoice = Invoice.objects.get(id=invoice_id, owner=request.user)
    return JsonResponse({"total": invoice.total})
