package com.scalashield.middleware

import zio.http._

/** Dev-only permissive CORS — allows any origin.
  * In production this is handled at the nginx layer with an explicit allowlist.
  * D-05/PLAN.md §3: CorsMiddleware sits before SecurityHeadersMiddleware in the stack.
  */
object CorsMiddleware:
  private val corsHeaders = Headers(
    Header.Custom("Access-Control-Allow-Origin", "*"),
    Header.Custom("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS"),
    Header.Custom("Access-Control-Allow-Headers", "Content-Type, Authorization"),
    Header.Custom("Access-Control-Max-Age", "3600"),
  )

  val dev: Middleware[Any] = Middleware.addHeaders(corsHeaders)
