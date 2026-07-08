package com.scalashield.middleware

import zio.http._

/** Phase 1 security checkpoint (PLAN.md section 6): CSP, HSTS,
  * X-Frame-Options, X-Content-Type-Options on every response. */
object SecurityHeadersMiddleware:
  private val securityHeaders: Headers = Headers(
    Header.Custom("Content-Security-Policy", "default-src 'self'"),
    Header.Custom("Strict-Transport-Security", "max-age=31536000"),
    Header.XFrameOptions.Deny,
    Header.Custom("X-Content-Type-Options", "nosniff"),
  )

  val live: Middleware[Any] = Middleware.addHeaders(securityHeaders)
