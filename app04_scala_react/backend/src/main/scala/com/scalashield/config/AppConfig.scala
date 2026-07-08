package com.scalashield.config

import zio._

final case class AppConfig(
    dbHost: String,
    dbPort: Int,
    dbName: String,
    dbUser: String,
    dbPassword: String,
    httpPort: Int,
)

object AppConfig:
  private def env(name: String, default: String): String =
    scala.sys.env.getOrElse(name, default)

  val live: ZLayer[Any, Nothing, AppConfig] = ZLayer.succeed {
    AppConfig(
      dbHost = env("DB_HOST", "localhost"),
      dbPort = env("DB_PORT", "5432").toInt,
      dbName = env("DB_NAME", "scalashield"),
      dbUser = env("DB_USER", "scalashield"),
      dbPassword = env("DB_PASSWORD", "scalashield"),
      httpPort = env("HTTP_PORT", "8080").toInt,
    )
  }
