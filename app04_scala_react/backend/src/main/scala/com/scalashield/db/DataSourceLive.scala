package com.scalashield.db

import com.scalashield.config.AppConfig
import com.zaxxer.hikari.{HikariConfig, HikariDataSource}
import zio._

import javax.sql.DataSource

object DataSourceLive:
  val layer: ZLayer[AppConfig, Throwable, DataSource] =
    ZLayer.scoped {
      for
        cfg <- ZIO.service[AppConfig]
        ds <- ZIO.fromAutoCloseable(ZIO.attempt {
          val hc = new HikariConfig()
          hc.setJdbcUrl(s"jdbc:postgresql://${cfg.dbHost}:${cfg.dbPort}/${cfg.dbName}")
          hc.setUsername(cfg.dbUser)
          hc.setPassword(cfg.dbPassword)
          hc.setMaximumPoolSize(10)
          new HikariDataSource(hc)
        })
      yield (ds: DataSource)
    }
