package com.scalashield.config

import zio._

final case class AppConfig(
    dbHost: String,
    dbPort: Int,
    dbName: String,
    dbUser: String,
    dbPassword: String,
    httpPort: Int,
    jwtSecret: String,
    jwtExpirationHours: Int,
    adminUsername: String,
    adminPasswordHash: String,
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
      dbPassword = env("DB_PASSWORD", "sca.........."),
      httpPort = env("HTTP_PORT", "8080").toInt,
      // D-15: HS256 shared secret - must be ≥ 32 chars in production
      jwtSecret = env("JWT_SECRET", "dev-only-secret-CHANGE-IN-PRODUCTION-min32"),
      jwtExpirationHours = env("JWT_EXPIRATION_HOURS", "8").toInt,
      adminUsername = env("ADMIN_USERNAME", "admin"),
      // bcrypt hash of "changeme-dev-only__" — override via ADMIN_PASSWORD_HASH in every deployment
      adminPasswordHash = env("ADMIN_PASSWORD_HASH", "$2a$10$..................wz6"),
    )
  }
