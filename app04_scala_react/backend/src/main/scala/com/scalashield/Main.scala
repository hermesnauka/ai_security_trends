package com.scalashield

import com.scalashield.config.AppConfig
import com.scalashield.db.{DataSourceLive, FlywayMigrator}
import com.scalashield.middleware.{CorsMiddleware, SecurityHeadersMiddleware}
import com.scalashield.routes.{AuthRoutes, FrameworkRoutes, ThreatRoutes}
import zio._
import zio.http._

object Main extends ZIOAppDefault:

  private val healthRoute = Routes(
    Method.GET / "health" -> handler(Response.json("""{"status":"UP"}""")),
  )

  // Explicit OPTIONS preflight routes for CORS (browsers send OPTIONS before POST/PUT).
  // CORS headers are added to all responses by CorsMiddleware.dev below.
  private val optionsRoutes: Routes[Any, Response] = Routes(
    Method.OPTIONS / "api" / "v1" / "auth" / "login"  -> handler(Response.status(Status.NoContent)),
    Method.OPTIONS / "api" / "v1" / "frameworks"       -> handler(Response.status(Status.NoContent)),
    Method.OPTIONS / "api" / "v1" / "threats"          -> handler(Response.status(Status.NoContent)),
  )

  private val app =
    (FrameworkRoutes.routes ++ ThreatRoutes.routes ++ AuthRoutes.routes ++ healthRoute ++ optionsRoutes) @@
      CorsMiddleware.dev @@
      SecurityHeadersMiddleware.live

  private val serverConfigLayer: ZLayer[Any, Nothing, Server.Config] =
    ZLayer.succeed(
      Server.Config.default.port(scala.sys.env.get("HTTP_PORT").flatMap(_.toIntOption).getOrElse(8080))
    )

  override val run =
    (FlywayMigrator.migrate *> Server.serve(app))
      .provide(
        AppConfig.live,
        DataSourceLive.layer,
        serverConfigLayer,
        Server.live,
      )
