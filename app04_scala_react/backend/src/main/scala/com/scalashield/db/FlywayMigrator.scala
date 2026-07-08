package com.scalashield.db

import com.scalashield.config.AppConfig
import org.flywaydb.core.Flyway
import zio._

object FlywayMigrator:
  def migrate: ZIO[AppConfig, Throwable, Unit] =
    for
      cfg <- ZIO.service[AppConfig]
      _ <- ZIO.attempt {
        Flyway
          .configure()
          .dataSource(
            s"jdbc:postgresql://${cfg.dbHost}:${cfg.dbPort}/${cfg.dbName}",
            cfg.dbUser,
            cfg.dbPassword,
          )
          .locations("classpath:db/migration")
          .load()
          .migrate()
      }
    yield ()
