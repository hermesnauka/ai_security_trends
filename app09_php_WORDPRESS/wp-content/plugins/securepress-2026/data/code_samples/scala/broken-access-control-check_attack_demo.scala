// VULNERABLE — do not use in production
case GET -> Root / "invoices" / LongVar(id) =>
  invoiceRepo.findById(id).flatMap(Ok(_))
