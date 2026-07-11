// SECURE pattern
case GET -> Root / "invoices" / LongVar(id) as user =>
  // WHY: findByIdAndOwner scopes the row lookup to the authenticated user at the query level
  invoiceRepo.findByIdAndOwner(id, user.id).flatMap {
    case Some(invoice) => Ok(invoice)
    case None          => Forbidden()
  }
