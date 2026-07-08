package com.scalashield

import com.scalashield.config.AppConfig
import com.scalashield.db.{DataSourceLive, FlywayMigrator}
import com.scalashield.middleware.SecurityHeadersMiddleware
import com.scalashield.routes.{FrameworkRoutes, ThreatRoutes}
import zio._
import zio.http._

object Main extends ZIOAppDefault:

  private val healthRoute = Routes(
    Method.GET / "api" / "v1" / "health" -> handler(Response.text("ok")),
  )

  private val app = (FrameworkRoutes.routes ++ ThreatRoutes.routes ++ healthRoute) @@ SecurityHeadersMiddleware.live

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
